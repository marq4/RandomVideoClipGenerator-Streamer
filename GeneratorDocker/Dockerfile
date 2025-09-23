FROM ubuntu:latest

EXPOSE 8080

RUN mkdir -p /root/RandomVideos/share/

RUN apt update
RUN apt install -y python3.10
RUN apt install -y ffmpeg

ADD index.html /var/www/html/
ADD cors_server.py /var/www/html/

WORKDIR /root/RandomVideos/
ADD random_video_clip_streamer.py .
ADD stream.sh .

CMD ["./stream.sh"]
