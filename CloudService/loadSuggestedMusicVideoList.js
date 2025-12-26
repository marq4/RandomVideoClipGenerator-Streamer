/* eslint-env browser */

async function getSuggestedMusicVideoListJSON () {
  try {
    const response = await fetch('https://swo0pk82b9.execute-api.us-east-2.amazonaws.com/prod/list')
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error loading music videos:', error)
    throw error
  }
}

document.getElementById('loadSuggestedMusicVideoList').addEventListener('click', async () => {
  try {
    const musicVideoListJSON = await getSuggestedMusicVideoListJSON()
    console.log(musicVideoListJSON) // TMP
    const container = document.getElementById('musicVideoListContainer')
    container.innerHTML = '<p>Music Video List will be rendered here!</p>'
  } catch (error) {
    // Handle error in UI:
    const msg = 'Failed to load videos. ' +
                'I will greatly appreciate it if you contact me and let me know.'
    alert(msg)
  }
})
