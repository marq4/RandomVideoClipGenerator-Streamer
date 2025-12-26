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

function isValidVideoList (content) {
  return content && content.includes('youtube.com/watch')
}

function getFallbackVideos () {
  return `* Learn to Fly - Foo Fighters Rockin'1000 https://www.youtube.com/watch?v=JozAmXo2bDE
* Future - Life Is Good ft. Drake https://www.youtube.com/watch?v=l0U7SxXHkPY
* OK Go - The One Moment https://www.youtube.com/watch?v=QvW61K2s0tA`
}

function parseVideoListToHTML (content) {
  const lines = content.split('\n').filter(line => line.trim())
  let unorderedList = '<ul class="video-list">'
  lines.forEach(line => {
    // Match pattern: * Title URL:
    const match = line.match(/^\*\s*(.+?)\s+(https:\/\/[^\s]+)$/)
    if (match) {
      const titleArtist = match[1].trim()
      const url = match[2].trim()
      unorderedList += `<li>
        <a href="${url}" target="_blank" rel="noopener noreferrer">
        ${titleArtist}
        </a>
        </li>`
    }
  })
  unorderedList += '</ul>'
  console.log('unorderedList:', unorderedList) // TMP
  return unorderedList
}

document.getElementById('loadSuggestedMusicVideoList').addEventListener('click', async () => {
  const container = document.getElementById('musicVideoListContainer')
  let content = ''
  try {
    const data = await getSuggestedMusicVideoListJSON()
    console.log('Received data: ', data)
    content = data.content
    console.log('Content: ', content) // TMP
    if (!isValidVideoList(content)) {
      console.log('Invalid video list, using fallback.')
      content = getFallbackVideos()
    }
  } catch (error) {
    console.log('API error, using fallback: ', error)
    content = getFallbackVideos()
  } finally {
    container.innerHTML = parseVideoListToHTML(content)
  }
})
