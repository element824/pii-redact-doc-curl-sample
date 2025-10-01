# Detect and Redact Personally Identifying Information in Native Documents

This repository contains examples and commands for using **Azure AI Services Language Service** to detect and redact PII (Personally Identifiable Information) in native documents. This sample demonstrates the implementation of secure credential management using environment variables for PowerShell and cURL-based workflows.

## 📖 Official Documentation

This sample is based on the official Microsoft documentation:
**[Detect and redact Personally Identifying Information in native documents (preview)](https://learn.microsoft.com/en-us/azure/ai-services/language-service/personally-identifiable-information/how-to/redact-document-pii)**

## 🚀 About Azure AI Services Language Service

The Azure AI Services Language Service provides advanced natural language processing capabilities, including PII detection and redaction for native documents. This preview feature allows you to automatically identify and redact sensitive information while preserving document formatting.

## ✅ Prerequisites

- **Azure AI Services Language resource** (with PII detection capabilities enabled)
- Valid API subscription key for the Language Service
- Azure Blob Storage account with containers for source and target documents
- SAS tokens with appropriate permissions (valid for at least 24 hours)
- Input document in supported format (PDF, Word, etc.)
- PowerShell (for Windows users) or cURL (cross-platform)

## ⚙️ Environment Setup

1. Copy the example environment file and configure your Azure credentials:

```powershell
Copy-Item .env.example .env
```

2. Edit the `.env` file with your actual Azure AI Services credentials and storage URLs:

```env
# Azure AI Services Language Service Configuration
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

## 🔧 Commands

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

## ⚙️ Configuration

The `pii-detection.json` file contains:

- Document source and target locations (using environment variable placeholders: `${SOURCE_DOCUMENT_URL}` and `${TARGET_CONTAINER_URL}`)
- PII categories to detect (Person, Organization)
- Redaction policy (entityMask)

**Security Note**: The JSON file now uses environment variable placeholders instead of hardcoded SAS URLs, making it safe to commit to version control.

## 🔍 Supported PII Categories

This sample detects the following PII categories:

- **Person**: Names and personal identifiers
- **Organization**: Company names and organizational identifiers

You can modify the `piiCategories` array in `pii-detection.json` to include additional categories as supported by the Azure AI Services Language Service.

## 🔐 Security Features

- **Environment Variable Management**: Sensitive information (API keys, SAS tokens) stored in `.env` file
- **Gitignore Protection**: Prevents accidental commitment of secrets to version control
- **SAS Token Validation**: Scripts check for required environment variables before execution
- **Automated Cleanup**: Temporary processed files are automatically removed

## ⚠️ Important Notes

1. **SAS Token Expiry**: Ensure SAS tokens are valid for at least 24 hours
2. **API Response**: Successfully submitted jobs return HTTP 202 with an `operation-location` header containing the job URL
3. **Job Status**: Use the job ID from the operation-location to check status
4. **PowerShell vs cURL**: PowerShell tends to work more reliably for this API on Windows

## 📊 Example Job Status Response

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

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ✍️ Author

**Koushik Nagarajan** ([@element824](https://github.com/element824))

---

⭐ If you found this sample helpful, please consider giving it a star on GitHub!

_This sample demonstrates Azure AI Services Language Service capabilities for PII detection and redaction in native documents. Based on official Microsoft documentation with enhanced security practices._
