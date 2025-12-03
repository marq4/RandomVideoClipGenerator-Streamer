"""
Unit tests.
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
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest
from _pytest.monkeypatch import MonkeyPatch

from PythonCore import random_video_clip_generator as rvcg

EXAMPLE_VIDEOS_SUBFOLDER = 'example_videos'

# Setup:
example_video_titles = [
    "Deftones - You've Seen The Butcher [Official Music Video] $!.mp4",
    "Doja Cat ñá - Kiss Me More (Official Video) ft. SZA.mp4",
    "RaeSremmurd_NoType.mp4"
]
known_durations_local = [213, 315, 197]
given_durations_ci = [10, 12, 8]
def set_example_video_durations() -> dict[str, int]:
    """
    Create a dictionary containing the video file names and their known/given durations.
    Video durations depends on whether videos are real (local) or fake (CI).
    """
    result: dict[str, int] = {}
    if os.getenv('CI'):
        result = dict(zip(example_video_titles, given_durations_ci))
    else:
        # Assume 'local'. No other envs for now.
        result = dict(zip(example_video_titles, known_durations_local))
    return result
example_videos_with_durations : dict = set_example_video_durations()
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


# Tests:

def test_prepend_line(tmp_path: Path) -> None:
    """ Ensure file ends up with correct line at the top. """

    # Basic test: prepend reasonable line to normal file:
    top_line = "Top line.\n"
    bottom_line = "Bottom line.\n"
    basic_case_file_path = tmp_path / "prepend_line_file_basic_case.txt"
    basic_case_file_path.write_text(bottom_line)
    rvcg.prepend_line(str(basic_case_file_path), top_line)
    content = basic_case_file_path.read_text().splitlines()
    assert content[0] == top_line.rstrip("\n")
    assert content[-1] == bottom_line.rstrip("\n")

    # Edge case: ensure empty line doesn't cause problems:
    rvcg.prepend_line(str(basic_case_file_path), '')
    content = basic_case_file_path.read_text().splitlines()
    assert content[0] == top_line.rstrip("\n")
    assert content[-1] == bottom_line.rstrip("\n")

    # Edge case: ensure empty line & empty file doesn't cause problems:
    edge_case_file_path = tmp_path / "prepend_empty_line_file_edge_case.txt"
    edge_case_file_path.write_text(bottom_line)
    rvcg.prepend_line(str(edge_case_file_path), '')
    content = edge_case_file_path.read_text().splitlines()
    assert content[0] == bottom_line.rstrip("\n")
    assert content[-1] == bottom_line.rstrip("\n")

def test_prepend_line_invalid_file() -> None:
    """ Ensure invalid file raises error. """
    with pytest.raises(ValueError):
        rvcg.prepend_line("", "line")

def test_list_files_subfolder(monkeypatch: MonkeyPatch) -> None:
    """ Either video files are found, or subfolder isn't. """

    # Ensure all files in example_videos subfolder are found:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    monkeypatch.chdir(repo_root)
    monkeypatch.setattr(rvcg, 'SUBFOLDER', EXAMPLE_VIDEOS_SUBFOLDER)
    files = rvcg.list_files_subfolder()
    expected = set(example_videos_with_durations)
    actual_files_set = set(files)
    assert expected.issubset(actual_files_set), f"Missing files: {expected - actual_files_set}"

    # Ensure program exits if critical subfolder containing video files is not found:
    nonexistent_subfolder = 'nonexistent'
    monkeypatch.setattr(rvcg, 'SUBFOLDER', nonexistent_subfolder)
    with pytest.raises(FileNotFoundError,
                       match=f"Subfolder does not exist: {nonexistent_subfolder}. "):
        rvcg.list_files_subfolder()

def test_list_files_subfolder_empty(tmp_path: Path, monkeypatch: MonkeyPatch) -> None:
    """ Ensure program exits if subfolder is empty. """
    subfolder = tmp_path / rvcg.SUBFOLDER
    subfolder.mkdir()
    monkeypatch.chdir(tmp_path)
    with pytest.raises(SystemExit):
        rvcg.list_files_subfolder() # Works with SUBFOLDER global.

def test_select_video_at_random(monkeypatch: MonkeyPatch) -> None:
    """ Ensure returned path is inside subfolder and video name is valid. """
    files = list(example_videos_with_durations.keys())
    monkeypatch.setattr(rvcg, 'CURRENT_DIRECTORY', '/tmp')
    selected_video_full_path = rvcg.select_video_at_random(files)
    video_name = os.path.basename(selected_video_full_path)
    assert video_name in files
    assert 'videos' in selected_video_full_path

def test_get_video_duration() -> None:
    """ Either the duration of example videos is obtained, or a file is missing. """

    # Ensure duration is valid for example videos:
    repo_root = Path(__file__).parent.parent
    for example_video_name, expected_duration in example_videos_with_durations.items():
        video_path = repo_root / EXAMPLE_VIDEOS_SUBFOLDER / example_video_name
        actual_duration = rvcg.get_video_duration(0, str(video_path))
        assert expected_duration == actual_duration

    # Ensure program exits if a video is not found:
    nonexistent_video_file = 'nonexistent.mp4'
    with(pytest.raises(FileNotFoundError,
                       match=f"Video file not found: {nonexistent_video_file}. ")):
        rvcg.get_video_duration(0, nonexistent_video_file)

def test_choose_starting_point() -> None:
    """ Ensure starting point is valid for example videos. """
    for _, duration in example_videos_with_durations.items():
        starting_point = rvcg.choose_starting_point(duration)
        assert 0 <= starting_point <= duration - 1

def test_choose_starting_point_edge_cases(monkeypatch: MonkeyPatch) -> None:
    """ Ensure videos that are too short are properly handled. """
    # Video is less than 1 second long:
    with pytest.raises(ValueError):
        rvcg.choose_starting_point(0)

    # Video duration is less than min interval:
    monkeypatch.setattr(rvcg, 'INTERVAL_MIN', 12)
    with pytest.raises(ValueError):
        rvcg.choose_starting_point(11)

    # When video duration is min interval, starting point must be 0:
    monkeypatch.setattr(rvcg, 'INTERVAL_MIN', 12)
    result = rvcg.choose_starting_point(12)
    assert result == 0

def test_add_clip_to_tracklist() -> None:
    """ Ensure <track> element is correctly added to XML ElementTree. """
    video_name = 'no-video.mp4'
    start_time = 5
    stop_time = 10
    playlist = ET.Element('playlist')
    tracks = ET.SubElement(playlist, 'tracklist')
    rvcg.add_clip_to_tracklist(tracks, video_name, start_time, stop_time)
    track = tracks.find('track')
    assert track is not None
    location = track.find('location')
    assert location is not None
    assert location.text is not None
    assert location.text.startswith('file:///')
    assert video_name in location.text
    extension = track.find('extension')
    assert extension is not None
    options = [opt.text for opt in extension.findall('.//*') \
        if opt.tag.endswith('option')]
    assert f"start-time={start_time}" in options
    assert f"stop-time={stop_time}" in options
    assert 'no-audio' in options

def test_generate_random_video_clips_playlist_empty_video_list() -> None:
    """ Passing empty list of videos (or None ) makes first assert fail. """
    empty_video_list = ()
    with pytest.raises(AssertionError):
        rvcg.generate_random_video_clips_playlist(empty_video_list)
    with pytest.raises(AssertionError):
        rvcg.generate_random_video_clips_playlist(None)

def test_generate_random_video_clips_playlist_invalid_number_of_clips(
    monkeypatch: MonkeyPatch) -> None:
    """ Number of clips less than 1, or too large. """

    # Value less than 1:
    too_low_value = 0
    example_dummy_video_list = ['video.mp4']
    monkeypatch.setattr(rvcg, 'NUMBER_OF_CLIPS', too_low_value)
    with(pytest.raises(AssertionError,
                       match=f"Invalid number of clips: {too_low_value}. ")):
        rvcg.generate_random_video_clips_playlist(example_dummy_video_list)

    # Too large:
    too_large_value = sys.maxsize
    monkeypatch.setattr(rvcg, 'NUMBER_OF_CLIPS', too_large_value)
    with(pytest.raises(AssertionError,
                       match=f"Invalid number of clips: {too_large_value}. ")):
        rvcg.generate_random_video_clips_playlist(example_dummy_video_list)

def test_generate_random_video_clips_playlist_valid_xml(monkeypatch: MonkeyPatch) -> None:
    """ Ensure function generates a valid XML structure with correct elements. """
    example_dummy_video_list = ['video.mp4']
    # Mock return values from other functions:
    monkeypatch.setattr(rvcg, 'get_video_duration', lambda *_: 16)
    monkeypatch.setattr(rvcg, 'choose_starting_point', lambda *_: 0)
    monkeypatch.setattr('random.randint', lambda *_: 2)
    playlist = rvcg.generate_random_video_clips_playlist(example_dummy_video_list)
    assert playlist.tag == 'playlist'
    assert playlist.attrib['version'] == '1'
    assert playlist.attrib['xmlns'] == 'http://xspf.org/ns/0/'
    assert playlist.attrib['xmlns:vlc'] == 'http://www.videolan.org/vlc/playlist/0'
    tracklist = playlist.find('tracklist')
    assert tracklist is not None
