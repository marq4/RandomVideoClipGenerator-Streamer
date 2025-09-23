""" Live stream of random content from FFmpeg to HTTP. """

import os
import random
import subprocess
import sys
from time import sleep

PATH='/root/RandomVideos'
SUBFOLDER = 'share'
CONCAT_FILE = 'concat.txt'
NUM_CLIPS_AHEAD = 10
PADDING = 5
MIN_CLIP_LENGTH = 4
MAX_CLIP_LENGTH = 25
DEFAULT_CLIP_LENGTH = 6

def get_random_clip_entry(video: str, clip_length: int) -> str:
    """ Returns file VIDEO, inpoint, outpoint. """
    duration = get_video_duration(video)
    if duration <= clip_length + PADDING:
        start = 0
    else:
        start = random.randint(0, int(duration - clip_length-1))
    entry = f"file '{PATH}/{SUBFOLDER}/{video}' \n"
    entry += f"inpoint {start} \n"
    entry += f"outpoint {start + clip_length} \n"
    return entry
#

def refresh_concat(clip_length: int):
    """ Build a concat playlist file with random video segments. """
    videos = get_list_of_videos()
    with open(CONCAT_FILE, 'w', encoding='utf-8') as file:
        for num_clip in range(NUM_CLIPS_AHEAD):
            video = random.choice(videos)
            file.write(get_random_clip_entry(video, clip_length))
            if num_clip != NUM_CLIPS_AHEAD-1:
                file.write("\n")
#

def get_list_of_videos() -> list:
    """ Returns list of video titles inside SUBFOLDER. """
    subfolder_contents = os.listdir(SUBFOLDER)
    if subfolder_contents is None or len(subfolder_contents) < 1:
        print(f"There are no files under '{SUBFOLDER}' subfolder.")
        print('Please download some music videos here ' + \
                '(on your host OS, e.g. Windows).')
        sys.exit()
    return subfolder_contents
#

def get_video_duration(video: str) -> int:
    """ Extract video duration with ffprobe and subprocess.Popen.
        :return: Video duration in seconds. """
    assert video
    video = f"{SUBFOLDER}/{video}"
    result = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', \
            'v:0', '-show_entries', 'stream=duration', '-of', \
            'default=noprint_wrappers=1:nokey=1', video], capture_output=True, 
            check=False)
    duration = float(result.stdout)
    seconds = int(duration)
    # assert min_interval < seconds > 0, f"Video too short: {video} "
    return seconds
#

def try_to_accept_user_clip_length() -> int:
    """ Set and return clip_length to what user wants or 1 - MAX. """
    clip_length = DEFAULT_CLIP_LENGTH
    try:
        user_desire = sys.argv[1]
        clip_length = int(user_desire)
    except (ValueError, IndexError):
        pass
    clip_length = max(clip_length, MIN_CLIP_LENGTH)
    clip_length = min(clip_length, MAX_CLIP_LENGTH)
    return clip_length
#

def main() -> None:
    """
    * Run forever:
        + Keep FFmpeg alive.
        + Stream as HSL.
        + Refresh halfway through.
    """
    clip_length = try_to_accept_user_clip_length()
    while True:
        refresh_concat(clip_length)
        sleep(clip_length * (NUM_CLIPS_AHEAD // 2))
#

if __name__ == '__main__':
    main()
