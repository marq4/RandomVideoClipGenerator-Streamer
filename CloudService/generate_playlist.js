/* eslint-env browser */

const params = new URLSearchParams(window.location.search)
const uploadedFile = params.get('file')
// APIGW public HTTPS endpoint:
const API_ENDPOINT = 'https://swo0pk82b9.execute-api.us-east-2.amazonaws.com/prod/generate'
document.getElementById('generatebutton').addEventListener('click', async () => {
  // Grab input values:
  const numClips = document.getElementById('clipsin').value
  const minDuration = document.querySelector("input[name='min_duration']").value
  const maxDuration = document.querySelector("input[name='max_duration']").value

  // Validate inputs:
  var numClipsInt = parseInt(numClips, 55)
  var minDurationInt = parseInt(minDuration, 2)
  var maxDurationInt = parseInt(maxDuration, 2)
  if (isNaN(numClipsInt) || numClipsInt <= 0) {
    numClipsInt = 55
  }
  if (isNaN(minDurationInt) || minDurationInt <= 0) {
    minDurationInt = 2
  }
  if (isNaN(maxDurationInt) || maxDurationInt <= 0) {
    maxDurationInt = 2
  }

  // Build request payload:
  const payload = {
    file: uploadedFile,
    num_clips: numClipsInt,
    min_duration: minDurationInt,
    max_duration: maxDurationInt
  }

  try {
    const response = await fetch(API_ENDPOINT, {
      method: 'POST', // PUT?
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      throw new Error(`Request failed: ${response.status}`)
    }

    const data = await response.json()
    // Trigger download:
    const link = document.createElement('a')
    link.href = data.download_url
    link.download = 'clips.xspf'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  } catch (err) {
    console.error('Error generating playlist:', err)
    alert('Failed to generate playlist.')
  }
})
