<#
    .SYNOPSIS
        Bulk editing script for Confluence Labels
    .DESCRIPTION
        Allow users to Add, remove, and rename labels in Confluence

    .PARAMETER Action
        Provide the action you wish to execute.  Valid actions are 
            - add - Search for pages in the supplied Space that match the supplied currentLabel, and add the supplied newLabel to those pages.
            - remove - Search for pages in the supplied Space that match the supplied currentLabel, and remove currentLabel from those pages.
            - rename - Search for pages in the supplied Space that match the supplied currentLabel, and remove currentLabel and add newLabel to those pages.

    .PARAMETER Space
        The Space Key of the Space you wish to search
    
    .PARAMETER currentLabel
        Any selected action uses this parameter to find pages in the supplied space.

    .PARAMETER newLabel
        The new label to be created for the pages
         - add - The newLabel will be added to all pages that match the currentLabel and Space
         - rename - The newLabel will replace the currentLabel on all pages in the Space
         - remove - newLabel is not used

    .PARAMETER BaseUrl
        The base URL of the confluence site you are using.  You may set an environment variable (CONFLUENCE_BASE_URL) instead of supplying this value.

    .PARAMETER User
        The User of the confluence site you are using.  You may set an environment variable (CONFLUENCE_API_USER) instead of supplying this value.

    .PARAMETER ApiToken
        The API Token for the User of the confluence site you are using.  You may set an environment variable (CONFLUENCE_API_TOKEN) instead of supplying this value.

    .EXAMPLE
        Edit-ConfluenceLabels.ps1 rename PSIT oltp2dw sit-data-transformation -BaseUrl https://accruent.atlassian.net/ -User user@accruent.com -ApiToken MyApiToken

    .EXAMPLE
        Edit-ConfluenceLabels.ps1 remove PSIT oltp -BaseUrl https://accruent.atlassian.net/ -User user@accruent.com -ApiToken MyApiToken

    .EXAMPLE
        Edit-ConfluenceLabels.ps1 add PSIT data sit-data-transformation -BaseUrl https://accruent.atlassian.net/ -User user@accruent.com -ApiToken MyApiToken

    .NOTES
        In order to use this, you must have an API token for your Atlassian account.  Instructions for configuring an API token can be found at https://confluence.atlassian.com/cloud/api-tokens-938839638.html

        Adding the following environment variables shortens the commands considerably
            - CONFLUENCE_BASE_URL - https://accruent.atlassian.net/
            - CONFLUENCE_API_USER - user@accruent.com
            - CONFLUENCE_API_TOKEN - MyApiToken
#>

param(
    [ValidateSet('rename','remove', 'add')]
    [Parameter(Position=0, Mandatory)]
    [System.String] $Action,

    [Parameter(Position=1, Mandatory)]
    [System.String] $Space,

    [Parameter(Position=2, Mandatory)]
    [System.String] $currentLabel,

    [Parameter(Position=3)]
    [System.String] $newLabel,

    [System.String] $BaseUrl,
    [System.String] $User, 
    [System.String] $ApiToken
)

if ([System.String]::IsNullOrWhiteSpace($User)) {
    $User = $ENV:CONFLUENCE_API_USER    
}

if ([System.String]::IsNullOrWhiteSpace($ApiToken)) {
    $ApiToken = $ENV:CONFLUENCE_API_TOKEN;
}

if ([System.String]::IsNullOrWhiteSpace($BaseUrl)) {
    $BaseUrl = $ENV:CONFLUENCE_BASE_URL;
}

if ([System.String]::IsNullOrWhiteSpace($User) -or [System.String]::IsNullOrWhiteSpace($ApiToken)) {
    Write-Error "User and Api Token is required.  Either supply them via the -User and -ApiToken parameters or set environment variables named CONFLUENCE_API_USER and CONFLUENCE_API_TOKEN.";
}

$pair = "$($User):$($ApiToken)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

$encodedLabel = ([System.Web.HttpUtility]::UrlEncode($currentLabel))

$result = Invoke-RestMethod -Method GET -Uri "$($BaseUrl)wiki/rest/api/content/search?cql=space%3D$($Space)%20and%20type%3Dpage%20and%20label%3D'$($encodedLabel)'&expand=metadata.labels" -Headers $Headers


foreach ($item in $result.results) {
    Write-Host "Processing $($item.title)"
    if ($Action -eq "rename" -or $Action -eq "remove")
    {
        Write-Host "Removing $($currentLabel)"
        Invoke-RestMethod -Method DELETE -Uri "$($BaseUrl)wiki/rest/api/content/$($item.id)/label/$($encodedLabel)" -Headers $Headers | Out-Null
    }
    
    if ($Action -eq "rename" -or $Action -eq "add") {

        $labelBody = @();
        $labelBodyItem = @{
            prefix="global"
            name="$newLabel"
        }
        $labelBody += $labelBodyItem
        Write-Host "Adding $($newLabel)"
        Invoke-RestMethod -Method POST -Uri "$($BaseUrl)wiki/rest/api/content/$($item.id)/label" -Body (ConvertTo-Json $labelBody) -ContentType "application/json" -Headers $Headers | Out-Null
    }
}


