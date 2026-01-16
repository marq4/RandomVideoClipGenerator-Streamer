""" Random Video Clip Generator core. """


import json
import os
import random
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from subprocess import PIPE, Popen
from typing import (TYPE_CHECKING, Any, Literal, NamedTuple, TypedDict, Union,
                    cast)

if TYPE_CHECKING:
    from mypy_boto3_lambda.client import LambdaClient
    from mypy_boto3_s3.client import S3Client
else:
    S3Client = Any
    LambdaClient = Any


#===============================================================================
# Please set these values if simply running the stand-alone script locally:
NUMBER_OF_CLIPS = 5
INTERVAL_MIN = 4
INTERVAL_MAX = 8
SUBFOLDER_NAME = 'videos'
LARGEST_MIN = 15
LARGEST_MAX = 25
#===============================================================================

#  === Common globals and classes ===

# DO NOT CHANGE THIS or CD breaks:
__version__ = '4.7.2'

RUNNING_ENV_IS_LAMBDA = bool(os.getenv('AWS_LAMBDA_FUNCTION_NAME'))

def get_xml_playlist_file_path() -> str:
    """ Prepend /tmp/ to clips.xspf if env is Lambda. """
    suffix = ''
    if RUNNING_ENV_IS_LAMBDA:
        suffix = '/tmp/'
    return f"{suffix}clips.xspf"

XML_PLAYLIST = get_xml_playlist_file_path()

@dataclass
class VideoMetadata:
    """ Metadata for a video file. """
    filename: str
    duration: int

VideoItemTypes = Union[str, VideoMetadata]
VideoListTypes = Union[list[str], list[Path], list[VideoMetadata]]

#  === Additional local globals ===

CURRENT_DIRECTORY = os.path.dirname( os.path.abspath(__file__) )
SCRIPT_DIR = Path(__file__).parent
SUBFOLDER = SCRIPT_DIR / SUBFOLDER_NAME
VLC_BATCH_FILE = 'exevlc.bat'


#  === Cloud globals and classes ===

BucketKey = Literal['playlist_bucket', 'upload_bucket']

class CloudConfig(TypedDict):
    """" Type definition for Cloud configuration. """
    playlist_bucket: str
    upload_bucket: str

class APIGWResponse(TypedDict):
    """ Type definition for APIGW-Lambda proxy response. """
    statusCode: int
    headers: dict[str, str]
    body: str

class PlaylistParams(NamedTuple):
    """ Validated playlist generation parameters. """
    num_clips: int
    min_duration: int
    max_duration: int

def load_config_from_repo_root_cloud() -> CloudConfig:
    """ Load and parse config YAML. """
    import yaml  # pylint: disable=import-outside-toplevel
    config_path = Path(__file__).parent / 'config.yml'
    if not config_path.exists():
        return cast(CloudConfig, {
            'playlist_bucket_name': '',
            'upload_bucket_name': ''
        })
    with open(config_path, encoding='UTF-8') as f:
        config: CloudConfig = yaml.safe_load(f)
    return config

def get_bucket_name_cloud(config: CloudConfig, bucket_key: BucketKey) -> str:
    """ Get S3 bucket name from config. """
    bucket_name: str = ''
    if RUNNING_ENV_IS_LAMBDA:
        bucket_name = config[bucket_key]
    return bucket_name

DEFAULT_NUMBER_OF_CLIPS_CLOUD = 55
MAX_NUM_CLIPS_CLOUD = 1_000
DEFAULT_INTERVAL_MIN_CLOUD = 2
DEFAULT_INTERVAL_MAX_CLOUD = 2
OK_STATUS_CODE = 200
NOT_FOUND_STATUS_CODE = 404
values_getter = load_config_from_repo_root_cloud()
OUTPUT_BUCKET = get_bucket_name_cloud(values_getter, 'playlist_bucket')
UPLOAD_BUCKET = get_bucket_name_cloud(values_getter, 'upload_bucket')


#  === Common functions ===

def prepend_line(filename: str, line: str) -> None:
    """ Append line to beginning of file. """
    if not filename:
        raise ValueError(f"Cannot prepend line: '{line}' to invalid {filename}. ")
    if len(line) > 0:
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
    ET.ElementTree(playlist_et).write(XML_PLAYLIST, encoding='UTF-8', xml_declaration=False)
    prepend_line(XML_PLAYLIST, '<?xml version="1.0" encoding="UTF-8"?>')

def generate_random_video_clips_playlist(video_list: VideoListTypes,
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

    assert min_duration <= max_duration, \
        f"{min_duration=}, {max_duration=}"

    playlist = ET.Element('playlist', version='1', xmlns='http://xspf.org/ns/0/',
                          attrib={'xmlns:vlc': 'http://www.videolan.org/vlc/playlist/0'})
    tracks = ET.SubElement(playlist, 'trackList')

    assert 1 <= num_clips < sys.maxsize, \
        f"Invalid number of clips: {num_clips}. "

    for iteration in range(num_clips):
        item: object = random.choice(video_list)
        duration: int
        if isinstance(item, VideoMetadata):
            # Lambda env.
            video_file = item.filename + '.mp4'
            duration = int(item.duration)
            begin_at = random.randint(0, int(duration) - max_duration)
            clip_length = random.randint(min_duration, max_duration)
        else:
            # Local env.
            assert isinstance(item, Path), "Variable item should be a Path in local env. "
            video_file = str(item)
            duration = get_video_duration_local(iteration, video_file)
            begin_at = choose_starting_point_local(int(duration))
            clip_length = random.randint(INTERVAL_MIN, INTERVAL_MAX)
        play_to = begin_at + clip_length
        add_clip_to_tracklist(tracks, video_file, begin_at, play_to) # type: ignore[arg-type]

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


#  === Local functions ===

def display_version_and_exit_local():
    """ Simply print global __version__ value and exit. """
    if len(sys.argv) > 1 and sys.argv[1] in ['--version', '-v', 'version']:
        print(__version__)
        sys.exit(0)

def list_files_subfolder_local() -> list[Path]:
    """ Create a list of all files in (global) SUBFOLDER. """
    subfolder_path = Path(SUBFOLDER)
    if not subfolder_path.exists():
        raise FileNotFoundError(f"Subfolder does not exist: {SUBFOLDER}. ")
    subfolder_contents = [f for f in subfolder_path.iterdir() if f.is_file()]
    if not subfolder_contents:
        print(f"There are no files under {SUBFOLDER}. ")
        sys.exit()
    return subfolder_contents

def select_video_at_random_local(list_of_files: list[Path]) -> str:
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

def generate_playlist_local(video_list: list[Path]) -> ET.Element:
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
    playlist_path = os.path.abspath(XML_PLAYLIST)
    executable = Path(CURRENT_DIRECTORY) / VLC_BATCH_FILE
    assert Path(executable).exists(), f"""\n
        Windows Batch script that calls VLC: {VLC_BATCH_FILE} is missing.
        This file must exist in the same location as this script.
        Please download it from the repo (it's under PythonCore folder).
        """
    with Popen([executable, playlist_path]):
        pass

def local_main():
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
        local_main()


#  === Cloud functions ===

def validate_num_clips_cloud(desired: int) -> int:
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

def validate_min_duration_independent_cloud(desired: int) -> int:
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

def validate_max_duration_independent_cloud(desired: int) -> int:
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

def validate_minmax_durations_together_cloud(
    independently_correct_min: int,
    independently_correct_max: int
) -> tuple[int, int]:
    """
    Intervals are NOT independent.
    Just going for defaults for now.
    """
    min_interval = independently_correct_min
    max_interval = independently_correct_max
    if max_interval < min_interval:
        min_interval = DEFAULT_INTERVAL_MIN_CLOUD
        max_interval = DEFAULT_INTERVAL_MAX_CLOUD
    return (min_interval, max_interval)

def parse_into_dictios_cloud(path: str) -> list[dict[str, str]]:
    """
    Transform pairs from text file into array of dictionaries, splitting 
    the lines by the last occurrence of '.mp4 ::: '.
    """
    result: list[dict[str, str]] = []
    with open(path, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.replace('\r', '').replace('\0', '')
            line = line.replace('\n', '')
            line = line.replace('\ufeff', '')
            if '.mp4' in line:
                pair: dict[str, str] = {}
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
    s3.upload_file(XML_PLAYLIST,
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

def generate_playlist_cloud(pairs: list[dict[str, str]],
                      num_clips: int,
                      min_duration: int,
                      max_duration: int) -> None:
    """ Cloud wrapper for fundamental functionality. """
    video_metadata_list: list[VideoMetadata] = []
    for pair in pairs:
        file = list(pair.keys())[0]
        length = int(float(list(pair.values())[0].rstrip()))
        video_metadata_list.append(VideoMetadata(filename=file, duration=length))
    top_element = generate_random_video_clips_playlist(
        video_metadata_list,
        num_clips,
        min_duration,
        max_duration)
    create_xml_file(top_element)

def delete_playlist_after_download_cloud() -> None:
    """ Immediately delete the generated XML so no other user accidentally gets it. """
    import boto3  # pylint: disable=import-outside-toplevel
    lambda_client: LambdaClient = boto3.client('lambda') # type: ignore[assignment]
    lambda_client.invoke(
        FunctionName='DeletePlaylistAfterDownload',
        InvocationType='Event', # Must be async.
        Payload=json.dumps({'file_key': "clips.xspf"})
    )

def prepare_response_cloud(status_ok: bool, method: str, body: str) -> APIGWResponse:
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

def get_version_response_cloud() -> APIGWResponse:
    """ Just return the version to be displayed in the webpage. """
    body = json.dumps({
        'version': __version__
    })
    return prepare_response_cloud(True, 'GET', body)

def get_test_values_response_cloud(body: dict[str, Any]) -> APIGWResponse:
    """ Validate clips, min, max. """
    values = validate_and_get_parameters_cloud(body)
    body_json = json.dumps({
        'num_clips': values.num_clips,
        'min_duration': values.min_duration,
        'max_duration': values.max_duration
    })
    return prepare_response_cloud(True, 'POST', body_json)

def extract_parameters_cloud(body: dict[str, Any]) -> tuple[int, int, int]:
    """
    Convert them from string to int.
    If empty: default.
    Otherwise:
        If invalid: default.
        Clamp floor to 1.
        Convert to int.
    """
    extracted_num_clips = body.get('num_clips')
    extracted_min_duration = body.get('min_duration')
    extracted_max_duration = body.get('max_duration')

    # Number of clips:
    if extracted_num_clips is None or extracted_num_clips == '':
        int_num_clips = DEFAULT_NUMBER_OF_CLIPS_CLOUD
    else:
        try:
            int_num_clips = int(extracted_num_clips)
            int_num_clips = max(int_num_clips, 1)
        except ValueError:
            int_num_clips = DEFAULT_NUMBER_OF_CLIPS_CLOUD

    # Min interval:
    if extracted_min_duration is None or extracted_min_duration == '':
        int_min_duration = DEFAULT_INTERVAL_MIN_CLOUD
    else:
        try:
            int_min_duration = int(extracted_min_duration)
            int_min_duration = max(int_min_duration, 1)
        except ValueError:
            int_min_duration = DEFAULT_INTERVAL_MIN_CLOUD

    # Max interval:
    if extracted_max_duration is None or extracted_max_duration == '':
        int_max_duration = DEFAULT_INTERVAL_MAX_CLOUD
    else:
        try:
            int_max_duration = int(extracted_max_duration)
            int_max_duration = max(int_max_duration, 1)
        except ValueError:
            int_max_duration = DEFAULT_INTERVAL_MAX_CLOUD

    return (int_num_clips, int_min_duration, int_max_duration)

def validate_and_get_parameters_cloud(body: dict[str, Any]) -> PlaylistParams:
    """
    Extract and validate user parameters from request body.
    Returns: (num_clips, min_duration, max_duration).
    """
    (user_num_clips, user_min_duration, user_max_duration) = extract_parameters_cloud(body)
    num_clips = validate_num_clips_cloud(user_num_clips)
    min_duration_independent = validate_min_duration_independent_cloud(user_min_duration)
    max_duration_independent = validate_max_duration_independent_cloud(user_max_duration)
    (ok_min, ok_max) = \
        validate_minmax_durations_together_cloud(min_duration_independent, max_duration_independent)
    result = PlaylistParams(num_clips, ok_min, ok_max)
    return result

def get_playlist_response_cloud(event: dict[str, Any]) -> APIGWResponse:
    """ Handle XML playlist generation for web users. """
    import boto3  # pylint: disable=import-outside-toplevel
    s3: S3Client  = boto3.client('s3') # type: ignore[assignment]

    # Event comes from API GW as json.
    body_str: str = event['body']
    body: dict[str, Any] = json.loads(body_str)
    filename_s3 = body['file']

    local_filename = '/tmp/' + filename_s3

    # Read pairs from S3 object (user-uploaded video list text file):
    s3.download_file(UPLOAD_BUCKET, filename_s3, local_filename)

    pairs = parse_into_dictios_cloud(local_filename)

    # Validate parameters:
    (num_clips, min_duration, max_duration) = validate_and_get_parameters_cloud(body)

    generate_playlist_cloud(pairs, num_clips, min_duration, max_duration)

    download_url = send_final_xml_playlist_to_user_cloud(s3)

    response_body = json.dumps({
            'num_clips': num_clips,
            'min_duration': min_duration,
            'max_duration': max_duration,
            'download_url': download_url
    })
    return prepare_response_cloud(True, 'POST', response_body)

def get_invalid_response_cloud() -> APIGWResponse:
    """ Tell user what went wrong. """
    body = json.dumps({
        'error': 'Not Found',
        'message': 'The requested path does not exist.',
        'available_endpoints': ['/version', '/generate']
    })
    return prepare_response_cloud(False, '', body)

def cloud_main(event: dict[str, Any], _context: Any):
    """
    Default (original) name: lambda_handler.
    Main function for Cloud Service Lambda environment.
    """

    assert RUNNING_ENV_IS_LAMBDA is True, 'God help us. '
    assert XML_PLAYLIST.startswith('/tmp/'), \
        'AWS Lambda fs is read-only except for /tmp. '

    # Check which route was called (generate | version):
    route = event.get('rawPath', '')

    if route.endswith('/version'):
        return get_version_response_cloud()

    if route.endswith('/testvalues'):
        try:
            body = json.loads(event['body'])
        except (json.JSONDecodeError, KeyError):
            error_body = json.dumps({'error': 'Invalid JSON in request body.'})
            return prepare_response_cloud(False, '', error_body)
        return get_test_values_response_cloud(body)

    if route.endswith('/generate'):
        playlist_response = get_playlist_response_cloud(event)
        delete_playlist_after_download_cloud()
        return playlist_response

    return get_invalid_response_cloud()
