""" Unit tests. """

import os
from pathlib import Path
import pytest
import xml.etree.ElementTree as ET
from _pytest.monkeypatch import MonkeyPatch
import random_video_clip_generator as rvcg


# Actual videos under 'example_videos' folder with their durations in seconds:
example_videos_with_durations = {
		"Deftones - You've Seen The Butcher [Official Music Video] $!.mp4": 213,
		"Doja Cat ñá - Kiss Me More (Official Video) ft. SZA.mp4": 315,
		"RaeSremmurd_NoType.mp4": 197
}


def test_prepend_line(tmp_path: Path) -> None:
	""" Ensure file ends up with correct line at the top. """

	# Basic test: prepend reasonable line to normal file:
	top_line = "Top line.\n"
	bottom_line = "Bottom line.\n"
	basic_case_file_path = tmp_path / "prepend_line_file_basic_case.txt"
	basic_case_file_path.write_text(bottom_line)
	rvcg.prepend_line(str(basic_case_file_path), top_line)
	content = basic_case_file_path.read_text().splitlines()
	assert content[0] == top_line
	assert content[-1] == bottom_line

	# Edge case: ensure empty line doesn't cause problems:
	edge_case_file_path = tmp_path / "prepend_empty_line_file_edge_case.txt"
	edge_case_file_path.write_text(bottom_line)
	rvcg.prepend_line(str(basic_case_file_path), "")
	content = basic_case_file_path.read_text().splitlines()
	assert content[0] == bottom_line
	assert content[-1] == bottom_line
#

def test_prepend_line_invalid_file() -> None:
	""" Ensure invalid file raises error. """
	with pytest.raises(ValueError):
		rvcg.prepend_line("", "line")
#

def test_list_files_subfolder(monkeypatch: MonkeyPatch) -> None:
	""" Ensure all files in example_videos subfolder are found. """
	repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
	monkeypatch.chdir(repo_root)
	monkeypatch.setattr(rvcg, 'SUBFOLDER', 'example_videos')
	files = rvcg.list_files_subfolder()
	expected = set(example_videos_with_durations)
	actual_files_set = set(files)
	assert expected.issubset(actual_files_set, f"Missing files: {expected - actual_files_set}")
#

def test_list_files_subfolder_empty(tmp_path: Path, monkeypatch: MonkeyPatch) -> None:
	""" Ensure program exits if subfolder is empty. """
	subfolder = tmp_path / rvcg.SUBFOLDER
	subfolder.mkdir()
	monkeypatch.chdir(tmp_path)
	with pytest.raises(SystemExit):
		rvcg.list_files_subfolder() # Works with SUBFOLDER global. 
#

def test_select_video_at_random(monkeypatch: MonkeyPatch) -> None:
	""" Ensure returned path is inside subfolder and video name is valid. """
	files = example_videos_with_durations.keys()
	monkeypatch.setattr(rvcg, 'CURRENT_DIRECTORY', '/tmp')
	selected_video_full_path = rvcg.select_video_at_random(files)
	video_name = selected_video_full_path.split('/')[-1]
	assert video_name in files
	assert '/tmp/videos' in selected_video_full_path
#

def test_get_video_duration() -> None:
	""" Ensure duration is valid for example videos. """
	for example_video_name, expected_duration in example_videos_with_durations.items():
		path = f"../example_videos/{example_video_name}"
		actual_duration = rvcg.get_video_duration(0, path)
		assert expected_duration == actual_duration
#

def test_choose_starting_point() -> None:
	""" Ensure starting point is valid for example videos. """
	for _, duration in example_videos_with_durations.items():
		starting_point = rvcg.choose_starting_point(duration)
		assert 0 <= starting_point <= duration - 1
#

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
#

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
	assert track.find('location').text.startswith(f"file:///{video_name}")
	options = [opt.text for opt in track.findall('.//vlc:option')]
	assert f"start-time={start_time}"
	assert f"stop_time={stop_time}"
	assert 'no-audio' in options
#

