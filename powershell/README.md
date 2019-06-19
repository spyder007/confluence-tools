# Powershell Scripts for Confluence

This folder contains Powershell scripts for interacting with Confluence via the [Confluence Cloud Rest API](https://developer.atlassian.com/cloud/confluence/rest/).

Each script is documented, for help use `get-help`:

```powershell
$>get-help Edit-ConfluenceLabels.ps1
```

## Authentication

These scripts can accept parameters for the base URL of the Confluence site, the username, and the API Token for that user.  Alternatively, you can set environment variables for these values to prevent you from having to define them with each call.

|Environment Variable|Description|
|--------------------|-----------|
|CONFLUENCE_BASE_URL| The base URL of your Confluence Site|
|CONFLUENCE_API_USER| Your Confluence Username|
|CONFLUENCE_API_TOKEN| Your Confluence API Token|

> For instructions on creating an API Token, visit the [Confluence Documentation](https://confluence.atlassian.com/cloud/api-tokens-938839638.html)

These variables can be set using the following command:

```powershell
$> [Environment]::SetEnvironmentVariable("CONFLUENCE_BASE_URL", "https://subdomain.atlassian.net/", "User")
$> [Environment]::SetEnvironmentVariable("CONFLUENCE_API_USER", "myUserName", "User")
$> [Environment]::SetEnvironmentVariable("CONFLUENCE_API_TOKEN", "myApiToken", "User")
```