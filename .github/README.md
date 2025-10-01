# Repository Configuration

This directory contains configuration files and automation for managing repository settings.

## repository.json

The `repository.json` file defines the repository's metadata:

- **description**: The repository description displayed on GitHub
- **name**: The repository display name
- **topics**: Tags/topics that help categorize and discover the repository

### Current Configuration

```json
{
  "description": "A sample project demonstrating how to redact Personally Identifiable Information (PII) from documents using cURL commands. The repository provides scripts and examples—primarily in PowerShell—to help automate PII redaction workflows, making it easier to process sensitive data securely.",
  "name": "PII Redact Document cURL Sample",
  "topics": [
    "pii-redaction",
    "curl",
    "powershell",
    "data-security",
    "privacy",
    "sample-code",
    "data-processing",
    "automation",
    "document-redaction",
    "mit-license"
  ]
}
```

## Automation

The repository includes a GitHub Actions workflow (`workflows/update-repository-settings.yml`) that automatically applies the settings from `repository.json` to the GitHub repository whenever:

1. Changes are pushed to the `main` branch that modify `repository.json`
2. The workflow is manually triggered via workflow_dispatch

This ensures that repository metadata stays in sync with the configuration file and provides a version-controlled way to manage repository settings.

### Manual Trigger

To manually trigger the workflow:

1. Go to the "Actions" tab in the GitHub repository
2. Select "Update Repository Settings" workflow
3. Click "Run workflow"
4. Select the branch (usually `main`)
5. Click "Run workflow"

### Requirements

The workflow requires the `GITHUB_TOKEN` secret, which is automatically provided by GitHub Actions with the necessary permissions to update repository settings.
