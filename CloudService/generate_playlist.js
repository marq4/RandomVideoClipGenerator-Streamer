const params = new URLSearchParams(window.location.search)
const uploadedFile = params.get("file")
// APIGW public HTTPS endpoint:
const API_ENDPOINT = 'https://swo0pk82b9.execute-api.us-east-2.amazonaws.com/prod/generate'
document.getElementById("generatebutton").addEventListener("click", async () => {
        // Grab input values
        const numClips = document.getElementById("clipsin").value;
        const minDuration = document.querySelector("input[name='min_duration']").value;
        const maxDuration = document.querySelector("input[name='max_duration']").value;

        // Build request payload
        const payload = {
            file: uploadedFile,
            num_clips: parseInt(numClips, 10),
            min_duration: parseInt(minDuration, 10),
            max_duration: parseInt(maxDuration, 10)
        };

        try {
            const response = await fetch(API_ENDPOINT, {
                    method: "POST", // PUT?
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(payload)
            });

            if (!response.ok) {
                    throw new Error(`Request failed: ${response.status}`);
            }

            const data = await response.json();
            // Trigger download:
            const link = document.createElement("a");
            link.href = data.download_url;
            link.download = "clips.xspf";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

        } catch (err) {
            console.error("Error generating playlist:", err);
            alert("Failed to generate playlist.");
        }
});