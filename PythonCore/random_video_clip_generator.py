""" Random video clips player for:
    * Windows 10 (local with python command).
    * Web/Cloud service: https://www.randomvideoclipgenerator.com
"""

import json
import os
import random
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from subprocess import PIPE, Popen

import boto3
from mypy_boto3_s3.client import S3Client


#===============================================================================
# Please set these values if running the script locally:
NUMBER_OF_CLIPS = 5
INTERVAL_MIN = 4
INTERVAL_MAX = 8
SUBFOLDER = 'videos'
LARGEST_MIN = 15
LARGEST_MAX = 25
#===============================================================================


RUNNING_ENV_IS_LAMBDA = bool(os.getenv('AWS_LAMBDA_FUNCTION_NAME'))

XML_PLAYLIST_FILE = 'clips.xspf'
if RUNNING_ENV_IS_LAMBDA:
    XML_PLAYLIST_FILE = '/tmp/' + XML_PLAYLIST_FILE


# DO NOT CHANGE THIS or CD breaks:
__version__ = '4.2.1'


# Globals for local script:
CURRENT_DIRECTORY = os.path.dirname( os.path.abspath(__file__) )
VLC_BATCH_FILE = 'exevlc.bat'

# Globals for Cloud Service:
DEFAULT_NUMBER_OF_CLIPS_CLOUD = 55
MAX_NUM_CLIPS_CLOUD = 1_000
DEFAULT_INTERVAL_MIN_CLOUD = 2
DEFAULT_INTERVAL_MAX_CLOUD = 2
OUTPUT_BUCKET = 'rvcg-xml-playlist-4download2'
OK_STATUS_CODE = 200
NOT_FOUND_STATUS_CODE = 404


# _ Common code section _

def prepend_line(filename: str, line: str) -> None:
    """ Append line to beginning of file. """
    if not filename:
        raise ValueError(f"Cannot prepend line: '{line}' to invalid {filename}. ")
    if line is not None and len(line) > 0:
        with open(filename, 'r+', encoding='utf-8') as file:
            content = file.read()
            file.seek(0,0)
            file.write(line.rstrip("\r\n") + "\n" + content)

def add_clip_to_tracklist(track_list: ET.Element, \
    video: str, start: int, end: int) -> None:
    """ Add clip (track) to playlist.trackList sub element tree and mute.
        :param: track_list: Contains the clips.
        :param: video: The name of the video file to be cut.
        :param: start: Begin clip from.
        :param: end: Stop clip at. """
    assert track_list is not None and video and start >= 0
    track = ET.SubElement(track_list, 'track')
    if not RUNNING_ENV_IS_LAMBDA:
        # Convert to absolute path and proper URI format for VLC:
        abs_path = os.path.abspath(video)
        # Convert Windows backslashes to forward slashes:
        video_uri = abs_path.replace("\\", '/')
    else:
        video_uri = video
    # Ensure proper prefix:
    if not video_uri.startswith('file:///'):
        video_uri = f"file:///{video_uri}"
    ET.SubElement(track, 'location').text = video_uri
    extension = ET.SubElement(track, 'extension', \
        application='http://www.videolan.org/vlc/playlist/0')
    ET.SubElement(extension, 'vlc:option').text = f"start-time={start}"
    ET.SubElement(extension, 'vlc:option').text = f"stop-time={end}"
    ET.SubElement(extension, 'vlc:option').text = 'no-audio'

def create_xml_file(playlist_et: ET.Element) -> None:
    """ Finally write the playlist tree element as an xspf file to disk. """
    ET.ElementTree(playlist_et).write(XML_PLAYLIST_FILE, encoding='UTF-8', xml_declaration=False)
    prepend_line(XML_PLAYLIST_FILE, '<?xml version="1.0" encoding="UTF-8"?>')

def generate_random_video_clips_playlist(video_list: list,
        num_clips: int, min_duration: int, max_duration: int) -> ET.Element:
    """
    * Create playlist as an xml element tree.
    * Create tracklist as subelement of playlist. This contains the clips.
    * For each clip to be generated:
        + Select a video at random.
        + Choose beginning and end of clip from selected video.
        + Add clip to playlist.
    """
    assert video_list

    playlist = ET.Element('playlist', version='1', xmlns='http://xspf.org/ns/0/',
                          attrib={'xmlns:vlc': 'http://www.videolan.org/vlc/playlist/0'})
    tracks = ET.SubElement(playlist, 'trackList')

    assert 1 <= num_clips < sys.maxsize, \
        f"Invalid number of clips: {num_clips}. "

    for iteration in range(num_clips):
        if RUNNING_ENV_IS_LAMBDA:
            pair = random.choice(video_list)
            video_file = list(pair.keys())[0]
            video_file += '.mp4'
            duration = int(float(list(pair.values())[0].rstrip()))
        else:
            video_file = select_video_at_random_local(video_list)
            duration = get_video_duration_local(iteration, video_file)

        if RUNNING_ENV_IS_LAMBDA:
            begin_at = random.randint(0, duration - max_duration)
            clip_length = random.randint(min_duration, max_duration)
        else:
            begin_at = choose_starting_point_local(duration)
            clip_length = random.randint(INTERVAL_MIN, INTERVAL_MAX)
        play_to = begin_at + clip_length

        add_clip_to_tracklist(tracks, video_file, begin_at, play_to)

    return playlist

def verify_intervals_valid() -> None:
    """
    * Depending on the environment:
    * Either:
    *   Just make sure local users won't shoot themselves on the foot.
    *   Make sure default values for Cloud make sense.
    """
    assert LARGEST_MIN >= INTERVAL_MIN >= 1
    assert LARGEST_MAX >= INTERVAL_MAX >= 1


# _ Cloud code section _

def validate_num_clips_cloud(desired: str) -> int:
    """ TRY to give the user the number of clips they desire. """
    try:
        num_clips = int(desired)
    except ValueError:
        return DEFAULT_NUMBER_OF_CLIPS_CLOUD
    if num_clips > MAX_NUM_CLIPS_CLOUD:
        return MAX_NUM_CLIPS_CLOUD
    if num_clips < 1:
        return 1
    return num_clips

def validate_min_duration_cloud(desired: str) -> int:
    """ Shortest clip in playlist can be between 1 and LARGEST_MIN seconds. """
    try:
        shortest = int(desired)
    except ValueError:
        return DEFAULT_INTERVAL_MIN_CLOUD
    if shortest < 1:
        return 1
    if shortest > LARGEST_MIN:
        return LARGEST_MIN
    return shortest

def validate_max_duration_cloud(desired: str) -> int:
    """ Longest clip in playlist can be between 1 and LARGEST_MAX seconds. """
    try:
        longest = int(desired)
    except ValueError:
        return DEFAULT_INTERVAL_MAX_CLOUD
    if longest < 1:
        return 1
    if longest > LARGEST_MAX:
        return LARGEST_MAX
    return longest

def parse_into_dictios_cloud(path: str) -> list:
    """
    Transform pairs from text file into array of dictionaries, splitting 
    the lines by the last occurrence of '.mp4 ::: '.
    """
    result = []
    with open(path, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.replace('\r', '').replace('\0', '')
            line = line.replace('\n', '')
            line = line.replace('\ufeff', '')
            if '.mp4' in line:
                pair = {}
                (key, val) = line.rsplit('.mp4 ::: ', 1)
                pair[key] = val
                result.append(pair)
    return result

def send_final_xml_playlist_to_user_cloud(s3: S3Client) -> str:
    """
    To allow the user's browser to download the resulting file:
        + Upload XML playlist to S3.
        + Generate pre-signed URL???
    """
    object_key = "clips.xspf"
    s3.upload_file(XML_PLAYLIST_FILE,
                    OUTPUT_BUCKET,
                    object_key,
                    ExtraArgs={
                        'ContentType': 'application/xspf+xml',
                        'ContentDisposition': 'attachment; filename="clips.xspf"',
                        'ACL': 'public-read'
                    }
    )
    url = f"https://{OUTPUT_BUCKET}.s3.us-east-2.amazonaws.com/{object_key}"
    return url

def generate_playlist_cloud(pairs: list,
                      num_clips: int,
                      min_duration: int,
                      max_duration: int) -> None:
    """ Cloud wrapper for fundamental functionality. """
    top_element = generate_random_video_clips_playlist(
        pairs,
        num_clips,
        min_duration,
        max_duration)
    create_xml_file(top_element)

def delete_playlist_after_download_cloud() -> None:
    """ Immediately delete the generated XML so no other user accidentally gets it. """
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName='DeletePlaylistAfterDownload',
        InvocationType='Event', # Must be async.
        Payload=json.dumps({'file_key': "clips.xspf"})
    )

def prepare_response_cloud(status_ok: bool, method: str, body: str) -> dict:
    """ Return JSON-like dictionary to return to Lambda caller (APIGW). """
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    if method != '':
        headers['Access-Control-Allow-Methods'] = method
    return {
        'statusCode': OK_STATUS_CODE if status_ok else NOT_FOUND_STATUS_CODE,
        'headers': headers,
        'body': body
    }

def get_version_response_cloud() -> dict:
    """ Just return the version to be displayed in the webpage. """
    body = json.dumps({
        'version': __version__
    })
    return prepare_response_cloud(True, 'GET', body)

def get_playlist_response_cloud(event: dict) -> dict:
    """ Handle XML playlist generation for web users. """
    s3 = boto3.client('s3')

    # Bucket name where user's video list text files are uploaded to:
    bucket_name = 'rvcgstack-s3uploadbucket-bcgfzvlvljdy'

    # Event comes from API GW as json.
    body = json.loads(event['body'])
    filename_s3 = body['file']
    user_num_clips = body['num_clips']
    user_min_duration = body['min_duration']
    user_max_duration = body['max_duration']

    local_filename = '/tmp/' + filename_s3

    # Read pairs from S3 object (user-uploaded video list text file):
    s3.download_file(bucket_name, filename_s3, local_filename)

    pairs = parse_into_dictios_cloud(local_filename)

    num_clips = validate_num_clips_cloud(user_num_clips)
    min_duration = validate_min_duration_cloud(user_min_duration)
    max_duration = validate_max_duration_cloud(user_max_duration)

    generate_playlist_cloud(pairs, num_clips, min_duration, max_duration)

    download_url = send_final_xml_playlist_to_user_cloud(s3)

    body = json.dumps({
            'num_clips': num_clips,
            'min_duration': min_duration,
            'max_duration': max_duration,
            'download_url': download_url
    })
    return prepare_response_cloud(True, 'POST', body)

def get_invalid_response_cloud() -> dict:
    """ Tell user what went wrong. """
    body = json.dumps({
        'error': 'Not Found',
        'message': 'The requested path does not exist.',
        'available_endpoints': ['/version', '/generate']
    })
    return prepare_response_cloud(False, '', body)

def cloud_main(event, _context):
    """ Main function for Cloud Service Lambda environment. """

    assert RUNNING_ENV_IS_LAMBDA is True, 'God help us. '
    assert XML_PLAYLIST_FILE.startswith('/tmp/'), \
        'AWS Lambda fs is read-only except for /tmp. '

    # Check which route was called (generate | version):
    route = event.get('rawPath', '')

    if route.endswith('/version'):
        return get_version_response_cloud()

    if route.endswith('/generate'):
        playlist_response = get_playlist_response_cloud(event)
        delete_playlist_after_download_cloud()
        return playlist_response

    return get_invalid_response_cloud()


# _ Local code section _

def display_version_and_exit_local():
    """ Simply print global __version__ value and exit. """
    if len(sys.argv) > 1 and sys.argv[1] in ['--version', '-v', 'version']:
        print(__version__)
        sys.exit(0)

def list_files_subfolder_local() -> list:
    """ Create a list of all files in (global) SUBFOLDER. """
    subfolder_path = Path(SUBFOLDER)
    if not subfolder_path.exists():
        raise FileNotFoundError(f"Subfolder does not exist: {SUBFOLDER}. ")
    subfolder_contents = [f.name for f in subfolder_path.iterdir() if f.is_file()]
    if not subfolder_contents:
        print(f"There are no files under {SUBFOLDER}. ")
        sys.exit()
    return subfolder_contents

def select_video_at_random_local(list_of_files: list) -> str:
    """ Choose a video. :return: Video filename with Win full path. """
    assert list_of_files and SUBFOLDER
    subfolder_path = Path(CURRENT_DIRECTORY) / SUBFOLDER
    selected = random.randint(0, len(list_of_files) - 1)
    return str((subfolder_path / list_of_files[selected]).resolve())

def get_video_duration_local(num_to_log: int, video: str) -> int:
    """ Extract video duration with ffprobe and subprocess.Popen.
        :return: Video duration in seconds. """
    assert video
    # Verify video file exists:
    if not os.path.exists(video):
        raise FileNotFoundError(f"Video file not found: {video}. ")
    video_path = Path(video)
    command_as_list = [
        'ffprobe', '-v', 'error',
        '-select_streams', 'v:0',
        '-show_entries', 'stream=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        str(video_path)
    ]
    try:
        result = subprocess.run(
            command_as_list,
            stdout=PIPE,
            stderr=PIPE,
            text=True,
            check=True,
            encoding='utf-8'
        )
        duration_str = result.stdout.strip()
        seconds = int(float(duration_str))
    except subprocess.CalledProcessError as e:
        print(f"FFprobe error on iteration {num_to_log}: {e.stderr}. ")
        raise
    except (ValueError, IndexError) as e:
        print(f"Could not parse duration for video: {video}. Error: {e}. ")
        raise
    assert INTERVAL_MIN < seconds and seconds > 0, f"Video too short: {video}. "
    return seconds

def choose_starting_point_local(video_length: int) -> int:
    """ Choose beginning of clip.
    :return: Starting point from beginning of video to end of video - max. """
    if video_length < 1:
        raise ValueError('Video too short. Videos must be at least 1 second long. ')
    if video_length < INTERVAL_MIN:
        raise ValueError(f"Video too short: {video_length}. Minimum interval is: {INTERVAL_MIN}. ")
    if video_length == INTERVAL_MIN:
        return 0
    return random.randint(0, video_length - INTERVAL_MAX)

def generate_playlist_local(video_list: list) -> ET.Element:
    """ Local wrapper for fundamental functionality. """
    top_element = generate_random_video_clips_playlist(
        video_list,
        NUMBER_OF_CLIPS,
        INTERVAL_MIN,
        INTERVAL_MAX)
    create_xml_file(top_element)
    return top_element

def execute_vlc_local() -> None:
    """ Call VLC only once and pass it the xspf playlist. """
    # Use absolute path for the playlist:
    playlist_path = os.path.abspath(XML_PLAYLIST_FILE)
    executable = Path(CURRENT_DIRECTORY) / VLC_BATCH_FILE
    print(f"{executable=}")#TMP
    assert Path(executable).exists(), f"""\n
        Windows Batch script that calls VLC: {VLC_BATCH_FILE} is missing.
        This file must exist in the same location as this script.
        Please download it from the repo (it's under PythonCore folder).
        """
    with Popen([executable, playlist_path]):
        pass

def main():
    """
    * Get list of videos.
    * Generate an xml playlist with random clips from those videos.
    * Run VLC with that playlist.
    """
    # Only if --version passed:
    display_version_and_exit_local()
    verify_intervals_valid()
    files = list_files_subfolder_local()
    top_element = generate_playlist_local(files)
    create_xml_file(top_element)
    execute_vlc_local()

if __name__ == "__main__":
    if not RUNNING_ENV_IS_LAMBDA:
        main()
