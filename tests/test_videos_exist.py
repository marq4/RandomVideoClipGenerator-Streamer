"""
Verify video URLs are valid and videos exist.
No main, Pytest will run all functions that stat with 'test'.
"""

import pytest

from core_utils import (GOOGLE_API_KEY, invalid_url_should_fail,
                           verify_videos_exist)


@pytest.mark.integration
def test_videos_exist() -> None:
    """
    Goes to YouTube and checks if videos listed in music video list test file exist.
    """
    assert verify_videos_exist(GOOGLE_API_KEY)
#

@pytest.mark.integration
def test_invalid_url_should_fail() -> None:
    """
    Negative test: invalid YouTube music video id should fail.
    """
    assert invalid_url_should_fail(GOOGLE_API_KEY) is False
