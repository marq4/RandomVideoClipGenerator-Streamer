// Fetch version on page load.
async function fetchAndDisplayVersion () {
  try {
    const response = await fetch('https://AAAAAAAAAswo0pk82b9.execute-api.us-east-2.amazonaws.com/prod/version')
    const data = await response.json()
    document.getElementById('app-version').textContent = data.version
  } catch (error) {
    console.error('Failed to fetch version:', error)
    // Fallback to hardcoded version if API fails:
    document.getElementById('app-version').textContent = '4.0.0'
  }
}
// Call when page loads:
window.addEventListener('DOMContentLoaded', fetchAndDisplayVersion)
