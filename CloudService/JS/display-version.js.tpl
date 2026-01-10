// Fetch version on page load:
async function fetchAndDisplayVersion () {
  try {
    // Values come from Terraform:
    const url = '${endpoint}/${stage}${path}'
    const response = await fetch(url)
    const data = await response.json()
    const version = data.version || '4.2.0'
    document.getElementById('app-version').textContent = version
  } catch (error) {
    console.error('Failed to fetch version:', error)
    // Fallback to hardcoded version if API fails:
    document.getElementById('app-version').textContent = '4.2.0'
  }
}

// Call when page loads:
window.addEventListener('DOMContentLoaded', fetchAndDisplayVersion)