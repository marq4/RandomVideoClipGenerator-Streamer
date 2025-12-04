""" Integration tests. """

import sys
from pathlib import Path

# Add project root to path:
sys.path.insert(0, str(Path(__file__).parent.parent))

# Do not remove this comment or code quality breaks:
# pylint: disable=wrong-import-position
from unit_tests import EXAMPLE_VIDEOS_SUBFOLDER, example_video_titles

from PythonCore import random_video_clip_generator as rvcg


def test_verify_example_videos_available() -> None:
    """ Ensure example videos (local: real, CI: fake) are there. """
    subfolder_path = Path(EXAMPLE_VIDEOS_SUBFOLDER)
    assert subfolder_path.exists(), f"Example videos folder missing: {subfolder_path}. "
    subfolder_contents = [file.name for file in subfolder_path.iterdir() if file.is_file()]
    actual_content_length = len(subfolder_contents)
    expected_content_length = len(example_video_titles)
    assert actual_content_length == expected_content_length, \
        f"""Expected {expected_content_length} videos,
        but instead found {actual_content_length}. """

def test_playlist_creation() -> None:
    """ IT: get video durations -> generate XML -> validate. """
    # Absolute paths to video files required:
    repo_root = Path(__file__).parent.parent
    subfolder_contents : list[str] = []
    for example_video_name in example_video_titles:
        absolute_video_path = repo_root / EXAMPLE_VIDEOS_SUBFOLDER / example_video_name
        subfolder_contents.append(absolute_video_path)
    real_playlist = rvcg.generate_random_video_clips_playlist(subfolder_contents)
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
        # start-time, stop-time, no-audio:
        assert len(options) == 3
