# PowerShell script to check the status of the last submitted job
# Usage: .\check-job-status.ps1 [jobId]

param(
    [string]$JobId
)

# Load environment variables from .env file
if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.+)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
} else {
    Write-Error ".env file not found! Please create one based on .env.example"
    exit 1
}

# Get job ID from parameter or last job info file
if (-not $JobId) {
    if (Test-Path "last-job-info.json") {
        $jobInfo = Get-Content "last-job-info.json" | ConvertFrom-Json
        $JobId = $jobInfo.JobId
        Write-Host "Using job ID from last submission: $JobId"
    } else {
        Write-Error "No job ID provided and no last-job-info.json found. Please provide a job ID as parameter."
        Write-Host "Usage: .\check-job-status.ps1 <jobId>"
        exit 1
    }
}

# Check required environment variables
if (-not $env:AZURE_LANGUAGE_ENDPOINT -or -not $env:AZURE_LANGUAGE_API_KEY -or -not $env:API_VERSION) {
    Write-Error "Missing required environment variables. Please check your .env file."
    exit 1
}

# Check job status
Write-Host "Checking status for job: $JobId"
$headers = @{
    'Ocp-Apim-Subscription-Key' = $env:AZURE_LANGUAGE_API_KEY
    'Content-Type' = 'application/json'
}

$jobUrl = "$env:AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs/$JobId" + "?api-version=$env:API_VERSION"

try {
    $statusResponse = Invoke-RestMethod -Uri $jobUrl -Method GET -Headers $headers
    
    Write-Host "Job Status: $($statusResponse.status)" -ForegroundColor $(
        switch ($statusResponse.status) {
            "succeeded" { "Green" }
            "failed" { "Red" }
            "running" { "Yellow" }
            default { "White" }
        }
    )
    
    Write-Host "Created: $($statusResponse.createdDateTime)"
    Write-Host "Last Updated: $($statusResponse.lastUpdatedDateTime)"
    Write-Host "Expires: $($statusResponse.expirationDateTime)"
    
    if ($statusResponse.tasks) {
        Write-Host "`nTask Progress:"
        Write-Host "  Total: $($statusResponse.tasks.total)"
        Write-Host "  Completed: $($statusResponse.tasks.completed)"
        Write-Host "  In Progress: $($statusResponse.tasks.inProgress)"
        Write-Host "  Failed: $($statusResponse.tasks.failed)"
    }
    
    # Display full response in JSON format
    Write-Host "`nFull Response:" -ForegroundColor Cyan
    $statusResponse | ConvertTo-Json -Depth 10 | Write-Host
    
} catch {
    Write-Error "Failed to check job status: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)"
    }
}