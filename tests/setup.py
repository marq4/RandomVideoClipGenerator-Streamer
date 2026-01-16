"""
Setup:
    * A list contains the example video file names (with special characters).
    * I have downloaded these videos locally.
    * In the GitHub workflow, fake videos are generated (with the same names).
    * To break UT locally: change any local duration value.
    * To break UT in CI: under create_fake_example_videos set duration+1.
    * Changing value(s) for given durations for fake videos doesn't break
        the test as the files are both created with the arbitrary duration,
        and that same number is also used as expected value later.
    * Global example_videos_with_durations is set from 
        the list of titles + durations which depend on env (local|CI).
    * Finally the fake video files are created on the GitHub runner with given durations.
"""

import os
import subprocess
from pathlib import Path

EXAMPLE_VIDEOS_SUBFOLDER = 'example_videos'

example_video_titles = [
    Path("Deftones - You've Seen The Butcher [Official Music Video] $!.mp4"),
    Path("Doja Cat ñá - Kiss Me More (Official Video) ft. SZA.mp4"),
    Path("RaeSremmurd_NoType.mp4")
]

known_durations_local = [213, 315, 197]
given_durations_ci = [10, 12, 8]

def set_example_video_durations() -> dict[Path, int]:
    """
    Create a dictionary containing the video file names and their known/given durations.
    Video durations depends on whether videos are real (local) or fake (CI).
    """
    result: dict[Path, int] = {}
    if os.getenv('CI'):
        result = dict(zip(example_video_titles, given_durations_ci))
    else:
        # Assume 'local'. No other envs for now.
        result = dict(zip(example_video_titles, known_durations_local))
    return result

example_videos_with_durations : dict[Path, int] = set_example_video_durations()

def create_fake_example_videos() -> None:
    """ Using FFMpeg. For CI env only. """
    if not os.getenv('CI'):
        return
    subfolder = Path(EXAMPLE_VIDEOS_SUBFOLDER)
    subfolder.mkdir(exist_ok=True)
    assert subfolder.exists()
    for (filename, duration) in example_videos_with_durations.items():
        output_path = subfolder / filename
        subprocess.run([
            'ffmpeg', '-f', 'lavfi',
            '-i', f"testsrc=duration={duration}:size=320x240:rate=30",
            '-pix_fmt', 'yuv420p', '-y',
            str(output_path)
        ], check=True, capture_output=True)

create_fake_example_videos()
