""" Integration tests. """

import sys
from pathlib import Path

# Add project root to path:
sys.path.insert(0, str(Path(__file__).parent.parent))

# Do not remove this comment or code quality breaks:
# pylint: disable=wrong-import-position
from unit_tests import EXAMPLE_VIDEOS_SUBFOLDER, example_video_titles

def test_playlist_creation():
    """ Reuses fake videos generated during unit testing. """
    subfolder_path = Path(EXAMPLE_VIDEOS_SUBFOLDER)
    assert subfolder_path.exists(), f"Example videos folder missing: {subfolder_path}. "
    subfolder_contents = [file.name for file in subfolder_path.iterdir() if file.is_file()]
    actual_content_length = len(subfolder_contents)
    expected_content_length = len(example_video_titles)
    assert actual_content_length == expected_content_length, \
        f"Expected {expected_content_length} videos, found {actual_content_length}. "
