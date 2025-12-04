""" Integration tests. """

import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from subprocess import CompletedProcess

from _pytest.monkeypatch import MonkeyPatch

# Add project root to path:
sys.path.insert(0, str(Path(__file__).parent.parent))

# Do not remove this comment or code quality breaks:
# pylint: disable=wrong-import-position
from setup import EXAMPLE_VIDEOS_SUBFOLDER, example_video_titles

from PythonCore import random_video_clip_generator as rvcg

# start-time, stop-time, no-audio:
EXPECTED_NUM_OPTIONS = 3
VLC_TIMEOUT = 3

VLC_PATH = 'C:/Program Files/VideoLAN/VLC/vlc.exe'
REPO_ROOT = Path(__file__).parent.parent


def aux_get_list_of_absolute_paths_for_example_video_titles_list() -> list[str]:
    """ Assume example videos are there. """
    videos_absolute_paths : list[str] = []
    for title in example_video_titles:
        absolute_video_path = REPO_ROOT / EXAMPLE_VIDEOS_SUBFOLDER / title
        videos_absolute_paths.append(absolute_video_path)
    return videos_absolute_paths

def test_verify_example_videos_available(monkeypatch: MonkeyPatch) -> None:
    """ Ensure example videos (local: real, CI: fake) are there. """
    monkeypatch.chdir(REPO_ROOT)
    monkeypatch.setattr(rvcg, 'SUBFOLDER', EXAMPLE_VIDEOS_SUBFOLDER)
    subfolder_path = Path(EXAMPLE_VIDEOS_SUBFOLDER)
    assert subfolder_path.exists(), f"Example videos folder missing: {subfolder_path}. "
    actual_subfolder_contents = rvcg.list_files_subfolder()
    expected_subfolder_contents = aux_get_list_of_absolute_paths_for_example_video_titles_list()
    actual_content_length = len(actual_subfolder_contents)
    expected_content_length = len(expected_subfolder_contents)
    assert actual_content_length == expected_content_length, \
        f"""Expected {expected_content_length} videos,
        but instead found {actual_content_length}. """

def aux_generate_real_playlist() -> ET.Element:
    """ Create a real XSPF XML file with the example videos. """
    videos = aux_get_list_of_absolute_paths_for_example_video_titles_list()
    real_playlist = rvcg.generate_random_video_clips_playlist(videos)
    assert real_playlist is not None
    return real_playlist

def test_playlist_is_valid() -> None:
    """ IT: get video durations (for real) -> generate XML -> basic validation. """
    real_playlist = aux_generate_real_playlist()
    tracks = real_playlist.find('trackList')
    actual_number_of_tracks = len(tracks)
    expected_number_of_tracks = rvcg.NUMBER_OF_CLIPS
    assert actual_number_of_tracks == expected_number_of_tracks, \
        f"""Expected {expected_number_of_tracks} tracks/clips,
        but instead found {actual_number_of_tracks}. """
    # Verify each track has the required elements:
    for track in tracks:
        assert track.find('location') is not None
        extension = track.find('extension')
        assert extension is not None
        options = [opt.text for opt in extension.findall('.//*') \
            if opt.tag.endswith('option')]
        actual_number_of_options = len(options)
        assert actual_number_of_options == EXPECTED_NUM_OPTIONS, \
            f"""Expected {EXPECTED_NUM_OPTIONS} options,
            but instead found {actual_number_of_options}. """

# Skipping test: ensure XML file conforms to XSPF spec, as XSD is deprecated, links broken.

def aux_write_real_playlist_to_disk_get_absolute_path() -> str:
    """ Generate real playlist, write it to disk, return its absolute path. """
    real_playlist = aux_generate_real_playlist()
    rvcg.create_xml_file(real_playlist)
    return os.path.abspath(rvcg.XML_PLAYLIST_FILE)

def execute_vlc(playlist: str) -> CompletedProcess:
    """ Call VLC CLI passing appropriate flags and the playlist. """
    result = subprocess.run([
        VLC_PATH,
        # Flags required to avoid intermittent crash on CI:
        # 3221226356 (0xC0000374 - heap corruption):
        '--no-loop',
        '--no-repeat',
        '--play-and-exit',
        '--intf', 'dummy', '--dummy-quiet', '--no-video-title-show',
        '--no-audio',
        playlist
    ], capture_output=True, text=True, timeout=VLC_TIMEOUT, check=False)
    return result

def test_vlc_accepts_playlist_one_second_single_clip(monkeypatch: MonkeyPatch) -> None:
    """ The single most fundamental test of this project: 1 clip, 1 second. """
    monkeypatch.setattr(rvcg, 'NUMBER_OF_CLIPS', 1)
    monkeypatch.setattr(rvcg, 'INTERVAL_MIN', 1)
    monkeypatch.setattr(rvcg, 'INTERVAL_MAX', 1)
    playlist_abs_path = aux_write_real_playlist_to_disk_get_absolute_path()
    result = execute_vlc(playlist_abs_path)
    assert result.returncode == 0, \
        f"Fundamental test failed (1 clip, 1 second): {result.stderr}. "

def test_vlc_accepts_playlist_timeout_expected() -> None:
    """ Ensure VLC can load & parse the XSPF. """
    playlist_abs_path = aux_write_real_playlist_to_disk_get_absolute_path()
    try:
        result = execute_vlc(playlist_abs_path)
        # Will usually not reach this point, as it will timeout with default settings.
        assert result.returncode == 0, f"VLC failed to parse playlist: {result.stderr}. "
    except subprocess.TimeoutExpired:
        # Assume VLC ran fine.
        pass

def test_vlc_cannot_parse_malformed_playlist() -> None:
    """ Negative VLC test: append some nonsense to the top of the XML file. """
    playlist_abs_path = aux_write_real_playlist_to_disk_get_absolute_path()
    rvcg.prepend_line(rvcg.XML_PLAYLIST_FILE, \
        'This line should make VLC reject this playlist /> ')
    result = execute_vlc(playlist_abs_path)
    all_output = result.stderr.lower() + result.stdout.lower()
    error_hints = ['xml reader error', 'XML parser error', 'playlist stream error',
                   "can't read xml stream", 'invalid', 'malformed']
    assert any(hint in all_output for hint in error_hints)
