<!DOCTYPE html>
<html lang="en">
<head>
  <title>Random Video Clip Generator / Streamer</title>
  <link rel="stylesheet" href="${css}">
  <meta charset="UTF-8">
  <script src="https://unpkg.com/vue@1.0.28/dist/vue.js"></script>
  <script src="https://unpkg.com/axios@0.2.1/dist/axios.min.js"></script>
</head>
<body>
  <h1>Random Video Clip Generator / Streamer</h1>

  <div>
    <h3><a href="/about">What is this?</a></h3>
  </div>

  <div class="tabs-js">
    <div class="tab-buttons">
      <button class="tab-button active" data-tab="core" type="button">
        Python script
      </button>
      <button class="tab-button" data-tab="generator" type="button">
        Generator - Docker
      </button>
      <button class="tab-button" data-tab="cloud" type="button">
        Cloud Service
      </button>
    </div>

    <div class="tab-content" id="core">
    <div class="info">
      <h2>Instructions (Windows):</h2>
      <ol>
        <li>${install_ffmpeg}</li>
        <li>
          Install Python by following this
           <a href="https://phoenixnap.com/kb/how-to-install-python-3-windows">
            guide
          </a>.
        </li>
        <li>${install_vlc}</li>
        <li>
          Create this folder structure on your computer:
          <code>C:\Videos\videos</code>
        </li>
        <li>${download_music_videos}</li>
        <li>
          Download the
           <a href="https://${bucket}.s3.us-east-2.amazonaws.com/${core}">
           Python script
           </a>
           anywhere in your computer.
        </li>
        <li>
          Edit the script file. Specify:
          <ul>
            <li>Number of clips to play.</li>
            <li>Minimum clip duration (seconds).</li>
            <li>Maximum clip duration (seconds).</li>
          </ul>
        </li>
        <li>
          Execute the script to generate the playlist file:
           <code>python3 ${core}</code>
        </li>
        <li>
          Double-click the playlist file (clips.xspf):
           your video clips will appear on VLC media player.
           Press <code>f</code> key to toggle full-screen.
        </li>
      </ol>
    </div>
    </div>

    <div class="tab-content hidden" id="generator">
    <div class="info">
      <h2>Instructions (Windows):</h2>
      <ol>
        <li>
          Install
          <a href="https://docs.docker.com/get-started/introduction/get-docker-desktop/">
            Docker Desktop
          </a>.
        </li>
        <li>
          Create a directory (folder) under your C drive called 'share'.
        </li>
        <li>${download_music_videos}</li>
        <li>Start Docker Desktop.</li>
        <li>Open the Docker Desktop GUI.</li>
        <li>
          <ol>
            <li>Go to Docker Hub section on the right vertical menu.</li>
            <li>Search for and select "marq4/random_video_clip_streamer".</li>
            <li>Make sure the latest tag is selected. Click "Pull" button.</li>
            <li>
              Go to Images section. Select the image you just downloaded.
               Click the play button. Expand Optional Settings.
               Give your container a name, e.g. RandomVideoClipStreamerContainer (optional).
            </li>
            <li>Host Port: 8080.</li>
            <li>
              For the volumes: Host path: browse to <code>C:\share</code>. Container path: <code>/root/RandomVideos/share/</code>
            </li>
            <li>
              To optionally specify a clip duration set the Environment Variable name to: <code>USER_CLIP_LENGTH</code>. The valid range is between 3 and 25 seconds but the default and recommeneded minimun value is 6.
            </li>
            <li>Click "Run" button.</li>
          </ol>
        </li>
        <li>
          Open your web browser (like FireFox or Brave) and go to
           <code>http://localhost:8080</code>
        </li>
        <li>Reload the web browser as needed and wait for a couple of seconds.</li>
        <li>IF you don't see your video clips playing, please contact me.</li>
      </ol>
    </div>
    </div>

    <div class="tab-content hidden" id="cloud">
      <div class="info">
        <h2>Instructions (Windows):</h2>
        <ol>
          <li>${install_ffmpeg}</li>
          <li>${install_vlc}</li>
          <li>
            Create this folder structure on your computer:
             <code>C:\Videos\videos</code>
          </li>
          <li>${download_music_videos}</li>
          <li>
            Download the
             <a href="https://${bucket}.s3.us-east-2.amazonaws.com/GenerateList.ps1">
             PowerShell script
             </a>.
          </li>
          <li>Move it to <code>C:\Videos</code> folder. (⚠️ NOT videos subfolder 😉.)</li>
          <li>Run it:</li>
          <li>
            <ol>
              <li>Open an elevated PowerShell window by pressing <code>WIN+X</code>
                 and selecting Windows PowerShell (Admin).
                 (Select "yes" to User Account Control's dialog:
                 Do you want to allow this app to make
                 changes to your device?)
              </li>
              <li>
                Change-directory into your Videos folder: <code>cd C:\Videos</code>
              </li>
              <li>
                Execute the script: <br>
                <code>
                  powershell.exe -executionpolicy bypass -File .\GenerateList.ps1
                </code>
              </li>
              <li>
                Contact me if you don't see this: <code>Script complete.</code>
              </li>
            </ol>
          </li>
          <li>
            Upload your <code>list_videos.txt</code> to this web service.
            (Click the gray over blue "Browse... [No file selected]" button.)
            (Then select the text file, click "Open" button in your browser's "File Upload"
            window.)
            (Then click the new "Upload" button that will appear here.)
          </li>
          <li>
            After uploading your list of videos, click the
            <code> Generate Playlist</code> button in the next page.
          </li>
          <li>
            When you double-click the downloaded playlist, your video clips will
             appear on VLC media player. Press <code>f</code> key to toggle full-screen.
          </li>
        </ol>

        <div id="app" class="upload-form">
          <div v-if="!textFile">
            <h2 class="label">Select video list text file</h2>
            <input type="file" @change="onFileChange" accept="text/plain">
          </div>
          <div v-else>
            <button v-if="!uploadURL" @click="uploadFile" 
              class="actual-button" id="upload" type="button">
              Upload
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>

  <div class="music-video-list-section">
    <label for="load-suggested-music-video-list-button">
      Looking for music video suggestions?
    </label>
    <button id="load-suggested-music-video-list-button" type="button" class="actual-button">
      Show list
    </button>
    <div id="music-video-list-container">
    </div>
  </div>

  <footer>
    <p>
    Version: <span id="app-version"></span>
    </p>
  </footer>

  <script src="${tabs}"></script>
  <script src="${upload}"></script>
  <script src="${version}"></script>
  <script src="${list}"></script>

</body>
</html>
