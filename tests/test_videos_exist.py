""" Verify video URLs are valid and videos exist. """

import os
from typing import List
import pytest
import requests

API = "https://www.googleapis.com/youtube/v3/videos"
GOOGLE_API_KEY = os.environ["GOOGLEAPIYOUTUBEKEY"]

def get_response(google_api_key: str, video_id: str) -> requests.Response:
    """ Call YouTube API. """
    call_string = f"{API}?id={video_id}&part=id&key={google_api_key}"
    response = requests.get(call_string, timeout=6)
    return response

def check_response_valid(response: requests.Response) -> bool:
    """ Valid responses have at least one item. """
    return len(response.json().get('items', [])) >= 1

def get_list_of_videos() -> List[str]:
    """ Read from YouTube music video list text file. """
    video_list = []
    with open('List.md', 'r', encoding='utf-8') as video_list_text_file:
        for line in video_list_text_file.readlines():
            if line.startswith('https'):
                video_list.append(line.rstrip())
    return video_list

def transform_into_list_of_ids(video_list: list) -> List[str]:
    """ Parse URLs into just the YouTube video ids. """
    id_list = []
    pattern = 'v='
    for url in video_list:
        parts = url.split(pattern, 1) # Split once.
        if len(parts) > 1:
            id_list.append(parts[1])
        else:
            # Invalid URL found.
            return []
    return id_list

def verify_videos_exist(google_api_key: str) -> bool:
    """ Get all video URLs in a list. Check each one. """
    github_output = str(os.getenv('GITHUB_OUTPUT'))
    print(f"{github_output=}")#TMP
    broken_links = []
    videos = get_list_of_videos()
    ids = transform_into_list_of_ids(videos)
    for video_id in ids:
        response = get_response(google_api_key, video_id)
        if not check_response_valid(response):
            print(f"YouTube video NOT found: {video_id}! ")
            broken_links.append(video_id)
            continue
        print(f"YouTube video found: {video_id}. ")
    if len(broken_links) > 0:
        with open(github_output, 'a', encoding='UTF-8') as f:
            f.write(f"failed_urls={' '.join(broken_links)}\n")
        return False
    return True

def invalid_url_should_fail(google_api_key: str) -> bool:
    """ Negative test to avoid false positives. """
    non_existent_youtube_video_id = "09vuCByb6js"
    response = get_response(google_api_key, non_existent_youtube_video_id)
    return check_response_valid(response)

@pytest.mark.integration
def test_videos_exist() -> None:
    """
    Goes to YouTube and checks if videos listed in music video list test file exist.
    """
    assert verify_videos_exist(GOOGLE_API_KEY)

@pytest.mark.integration
def test_invalid_url_should_fail() -> None:
    """
    Negative test: invalid YouTube music video id should fail.
    """
    assert invalid_url_should_fail(GOOGLE_API_KEY) is False
