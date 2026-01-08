/* eslint-env browser */

const params = new URLSearchParams(window.location.search)
const uploadedFile = params.get('file')
// Value comes form Terraform. APIGW public HTTPS endpoint:
const API_ENDPOINT = '${endpoint}prod/generate'

document.getElementById('generatebutton').addEventListener('click', async () => {
  // Grab input values as strings:
  const numClips = document.getElementById('clipsin').value.trim()
  const minDuration = document.querySelector("input[name='min_duration']").value.trim()
  const maxDuration = document.querySelector("input[name='max_duration']").value.trim()

  // Build request payload - send strings, let backend handle validation:
  const payload = {
    file: uploadedFile,
    num_clips: numClips,
    min_duration: minDuration,
    max_duration: maxDuration
  }

  try {
    const response = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      throw new Error(`Request failed: $${response.status}`)
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