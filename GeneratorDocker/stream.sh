#! /bin/bash -

USER_CLIP_LENGTH=${USER_CLIP_LENGTH:-4}

cd /var/www/html/ && python3.10 cors_server.py &
sleep 1

python3.10 random_video_clip_streamer.py ${USER_CLIP_LENGTH} &
sleep 1

while [ ! -s /root/RandomVideos/concat.txt ]
do
  sleep 0.1
done

ffmpeg -re -f concat -safe 0 -i /root/RandomVideos/concat.txt \
  -c:v libx264 -c:a aac \
  -f hls -hls_time 4 -hls_list_size 5 \
  -hls_flags delete_segments+append_list+omit_endlist \
  /var/www/html/playlist.m3u8

