const MAX_LIST_SIZE = 5000000
const API_ENDPOINT = 'https://9xd9orynnk.execute-api.us-east-2.amazonaws.com/uploads'
new Vue({
        el: "#app",
        data: {
            textFile: '',
            uploadURL: ''
        },
        methods: {
            onFileChange(e) {
                    let files = e.target.files || e.dataTransfer.files
                    if (!files.length) return
                    this.loadTextFile(files[0])
            },
            loadTextFile(file) {
                    let reader = new FileReader()
                    reader.onload = (e) => {
                        // Store the file content (string) directly
                        this.textFile = e.target.result
                    }
                    reader.readAsText(file)  // Read as plain text instead of DataURL
            },
            uploadFile: async function () {
                    console.log('Upload clicked')

                    // Get the presigned URL from backend
                    const response = await axios({
                        method: 'GET',
                        url: API_ENDPOINT
                    })
                    console.log('Response: ', response)

                    // Convert text content to Blob
                    let blobData = new Blob([this.textFile], { type: 'text/plain' })

                    console.log('Uploading to: ', response.uploadURL)
                    const result = await fetch(response.uploadURL, {
                        method: 'PUT',
                        body: blobData
                    })
                    console.log('Result: ', result)

                    // Final URL (strip query string)
                    this.uploadURL = response.uploadURL.split('?')[0]

                    // Extract just the object key:
                    const objectKey = this.uploadURL.substring(this.uploadURL.lastIndexOf('/') + 1)

                    // Take user to playlist generation page:
                    window.location.href = `https://randomvideoclipgenerator.com/generate_playlist.html?file=${encodeURIComponent(objectKey)}`
            }
        }
})
