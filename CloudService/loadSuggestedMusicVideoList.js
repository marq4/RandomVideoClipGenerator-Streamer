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
  const urls = [
    'https://www.youtube.com/watch?v=JozAmXo2bDE',
    'https://www.youtube.com/watch?v=l0U7SxXHkPY',
    'https://www.youtube.com/watch?v=QvW61K2s0tA'
  ]
  return `<ul class="video-list">
    <li>
      <a href="${urls[0]}" target="_blank" rel="noopener noreferrer">
      Learn to Fly - Foo Fighters Rockin'1000
      </a>
    </li>
    <li>
      <a href="${urls[1]}" target="_blank" rel="noopener noreferrer">
      Future - Life Is Good ft. Drake
      </a>
    </li>
    <li>
      <a href="${urls[2]}" target="_blank" rel="noopener noreferrer">
      OK Go - The One Moment
      </a>
    </li>
  </ul>`
}

function parseVideoListToHTML (content) {
  let count = 0
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
      count++
    }
  })
  unorderedList += '</ul>'
  console.log('unorderedList:', unorderedList) // TMP
  return { unorderedList, count }
}

document.getElementById('load-suggested-music-video-list-button').addEventListener('click', async () => {
  const container = document.getElementById('music-video-list-container')
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
    const { html, count } = parseVideoListToHTML(content)
    if (count === 0) {
      content = getFallbackVideos()
    } else {
      content = html
    }
  } catch (error) {
    console.log('API error, using fallback: ', error)
    content = getFallbackVideos()
  } finally {
    container.innerHTML = content
  }
})
