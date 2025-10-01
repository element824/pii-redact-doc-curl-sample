# PowerShell script to process pii-detection.json with environment variable substitution
# Usage: .\process-config.ps1

# Load environment variables from .env file
if (Test-Path ".env") {
    Write-Host "Loading environment variables from .env file..."
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.+)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
            Write-Host "Set $($matches[1])"
        }
    }
} else {
    Write-Error ".env file not found! Please create one based on .env.example"
    exit 1
}

# Check required environment variables
$requiredVars = @("SOURCE_DOCUMENT_URL", "TARGET_CONTAINER_URL", "AZURE_LANGUAGE_ENDPOINT", "AZURE_LANGUAGE_API_KEY", "API_VERSION")
$missingVars = @()

foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Error "Missing required environment variables: $($missingVars -join ', ')"
    exit 1
}

# Read and process the JSON template
Write-Host "Processing pii-detection.json with environment variables..."
$jsonContent = Get-Content "pii-detection.json" -Raw

# Replace environment variable placeholders
$jsonContent = $jsonContent -replace '\$\{SOURCE_DOCUMENT_URL\}', $env:SOURCE_DOCUMENT_URL
$jsonContent = $jsonContent -replace '\$\{TARGET_CONTAINER_URL\}', $env:TARGET_CONTAINER_URL

# Create temporary processed file
$processedFile = "pii-detection-processed.json"
$jsonContent | Out-File -FilePath $processedFile -Encoding UTF8

Write-Host "Created processed configuration file: $processedFile"

# Submit the job
Write-Host "Submitting PII detection job..."
$headers = @{
    'Ocp-Apim-Subscription-Key' = $env:AZURE_LANGUAGE_API_KEY
    'Content-Type' = 'application/json'
}

$uri = "$env:AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs?api-version=$env:API_VERSION"

try {
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $jsonContent
    $jobUrl = $response.Headers['operation-location'][0]
    Write-Host "Job submitted successfully!" -ForegroundColor Green
    Write-Host "Job URL: $jobUrl" -ForegroundColor Yellow
    
    # Extract job ID from the URL
    if ($jobUrl -match '/jobs/([^?]+)') {
        $jobId = $matches[1]
        Write-Host "Job ID: $jobId" -ForegroundColor Yellow
        
        # Save job details for later reference
        $jobInfo = @{
            JobId = $jobId
            JobUrl = $jobUrl
            SubmittedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $jobInfo | ConvertTo-Json | Out-File -FilePath "last-job-info.json" -Encoding UTF8
        Write-Host "Job information saved to last-job-info.json"
    }
} catch {
    Write-Error "Failed to submit job: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
} finally {
    # Clean up temporary file
    if (Test-Path $processedFile) {
        Remove-Item $processedFile
        Write-Host "Cleaned up temporary file: $processedFile"
    }
}