#! /usr/bin/env bash

package_manager="none"


function subfolder_name_missing {
  echo "Subfolder name missing. "
  exit 1
}

function process_subdir {
  if [[ $# -ne 1 ]]
  then
    subfolder_name_missing
  fi

  list_file="list_$1.txt"
  
  rm --force ${list_file}
  
  cd $1
  for video_file in ./*.mp4
  do
    duration=$(ffprobe -v error -select_streams v:0 \
	    -show_entries stream=duration \
	    -of default=noprint_wrappers=1:nokey=1 "${video_file}")
    CWD=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    echo "$CWD/${video_file} ::: ${duration}" >> ../${list_file}
  done
  echo -e "\nCreated video list text file: ${list_file}. "
}

function install_ffmpeg {
  sudo $package_manager update &>/dev/null
  sudo $package_manager install ffmpeg -y
}

# Sets global var:
function get_supported_package_manager {
  if [[ -f /etc/debian_version ]]
  then
    package_manager="apt"
    return
  fi
  if [[ -f /etc/redhat-release ]]
  then
    package_manager="dnf"
    return
  fi 
  echo "Your distro is not supported. Please manually install ffmpeg. "
  echo "Please note that this script is meant ONLY for real Linux, not WSL or Git Bash!"
  exit 2
}


function verify_subdir_exists {
  if [[ $# -ne 1 ]]
  then
    subfolder_name_missing
  fi
  if [[ ! -d "$1" ]]
  then
    echo "Subfolder for videos does not exist. "
    echo "Default name is videos, or please specify a name. "
    exit 3
  fi
}

function main {
  videos_subfolder="videos"
  if [[ $# -ge 1 ]]
  then
    videos_subfolder=${1%/} # Remove trailing /. 
  fi
  verify_subdir_exists ${videos_subfolder}
  get_supported_package_manager
  install_ffmpeg
  process_subdir ${videos_subfolder}
}

main "$@"
