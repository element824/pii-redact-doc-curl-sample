# PII Detection and Redaction Manual

This repository contains examples and commands for using Azure Cognitive Services Language API for PII (Personally Identifiable Information) detection and redaction in documents.

## Prerequisites

- Azure Cognitive Services Language resource
- Valid API subscription key
- Blob storage with SAS tokens (valid for at least 24 hours)
- Input document and target container configured in `pii-detection.json`

## Environment Setup

1. Copy the example environment file and configure your Azure credentials:

```powershell
Copy-Item .env.example .env
```

2. Edit the `.env` file with your actual Azure credentials and storage URLs:

```env
# Azure Cognitive Services Configuration
AZURE_LANGUAGE_ENDPOINT=https://your-resource-name.cognitiveservices.azure.com
AZURE_LANGUAGE_API_KEY=your-api-key-here

# API Configuration
API_VERSION=2024-11-15-preview

# Azure Storage Configuration - Source Document
SOURCE_DOCUMENT_URL=https://your-storage-account.blob.core.windows.net/source-container/your-document.pdf?your-sas-token-here

# Azure Storage Configuration - Target Container
TARGET_CONTAINER_URL=https://your-storage-account.blob.core.windows.net/target-container?your-sas-token-here
```

3. **Important**: The `.env` file is already included in `.gitignore` to prevent committing sensitive information.

## Commands

### 1. Submit PII Detection Job

**PowerShell (Recommended) - Using the provided script:**

```powershell
# Submit job using the automated script
.\submit-job.ps1
```

This script will:

- Load environment variables from `.env`
- Process the `pii-detection.json` template with your actual URLs
- Submit the job to Azure
- Save job information for status checking

**Manual PowerShell (Alternative):**

```powershell
# Load environment variables from .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Process the JSON template with environment variables
$jsonContent = Get-Content 'pii-detection.json' -Raw
$jsonContent = $jsonContent -replace '\$\{SOURCE_DOCUMENT_URL\}', $env:SOURCE_DOCUMENT_URL
$jsonContent = $jsonContent -replace '\$\{TARGET_CONTAINER_URL\}', $env:TARGET_CONTAINER_URL

$headers = @{
    'Ocp-Apim-Subscription-Key' = $env:AZURE_LANGUAGE_API_KEY
    'Content-Type' = 'application/json'
}
$uri = "$env:AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs?api-version=$env:API_VERSION"
$response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $jsonContent
$jobUrl = $response.Headers['operation-location'][0]
Write-Host "Job submitted. Job URL: $jobUrl"
```

**cURL:**

```bash
# Load environment variables (Linux/Mac)
source .env
curl "$AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs?api-version=$API_VERSION" -i -X POST --header "Content-Type: application/json" --header "Ocp-Apim-Subscription-Key: $AZURE_LANGUAGE_API_KEY" --data "@pii-detection.json"

# Windows Command Prompt
for /f "tokens=1,2 delims==" %i in (.env) do set %i=%j
curl "%AZURE_LANGUAGE_ENDPOINT%/language/analyze-documents/jobs?api-version=%API_VERSION%" -i -X POST --header "Content-Type: application/json" --header "Ocp-Apim-Subscription-Key: %AZURE_LANGUAGE_API_KEY%" --data "@pii-detection.json"
```

### 2. Check Job Status

**PowerShell (Recommended) - Using the provided script:**

```powershell
# Check status of the last submitted job
.\check-job-status.ps1

# Or check a specific job by ID
.\check-job-status.ps1 -JobId "your-job-id-here"
```

**Manual PowerShell (Alternative):**

```powershell
# Load environment variables from .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

$headers = @{
    'Ocp-Apim-Subscription-Key' = $env:AZURE_LANGUAGE_API_KEY
    'Content-Type' = 'application/json'
}
$jobUrl = "$env:AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs/{jobId}?api-version=$env:API_VERSION"
$statusResponse = Invoke-RestMethod -Uri $jobUrl -Method GET -Headers $headers
$statusResponse
```

**cURL:**

```bash
# Load environment variables (Linux/Mac)
source .env
curl "$AZURE_LANGUAGE_ENDPOINT/language/analyze-documents/jobs/{jobId}?api-version=$API_VERSION" -i -X GET --header "Content-Type: application/json" --header "Ocp-Apim-Subscription-Key: $AZURE_LANGUAGE_API_KEY"

# Windows Command Prompt
for /f "tokens=1,2 delims==" %i in (.env) do set %i=%j
curl "%AZURE_LANGUAGE_ENDPOINT%/language/analyze-documents/jobs/{jobId}?api-version=%API_VERSION%" -i -X GET --header "Content-Type: application/json" --header "Ocp-Apim-Subscription-Key: %AZURE_LANGUAGE_API_KEY%"
```

## Configuration

The `pii-detection.json` file contains:

- Document source and target locations (using environment variable placeholders: `${SOURCE_DOCUMENT_URL}` and `${TARGET_CONTAINER_URL}`)
- PII categories to detect (Person, Organization)
- Redaction policy (entityMask)

**Security Note**: The JSON file now uses environment variable placeholders instead of hardcoded SAS URLs, making it safe to commit to version control.

## Important Notes

1. **SAS Token Expiry**: Ensure SAS tokens are valid for at least 24 hours
2. **API Response**: Successfully submitted jobs return HTTP 202 with an `operation-location` header containing the job URL
3. **Job Status**: Use the job ID from the operation-location to check status
4. **PowerShell vs cURL**: PowerShell tends to work more reliably for this API on Windows

## Example Job Status Response

```json
{
  "jobId": "9324449e-47cb-427e-a16e-0833956db472",
  "status": "running",
  "createdDateTime": "2025-10-01T08:51:46Z",
  "lastUpdatedDateTime": "2025-10-01T08:51:49Z",
  "expirationDateTime": "2025-10-02T08:51:46Z",
  "displayName": "Document PII Redaction example",
  "tasks": {
    "completed": 0,
    "failed": 0,
    "inProgress": 1,
    "total": 1
  }
}
```
