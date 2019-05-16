<#
    .SYNOPSIS
        Retrieve all labels from a Space and the number of pages on which that label is used.
    .DESCRIPTION
        This script scans the supplied space

    .PARAMETER Space
        The Space Key of the Space you wish to search
    
    .PARAMETER OutputFile
        A .csv filename which will be used to output the results of the search.
 
    .PARAMETER BaseUrl
        The base URL of the confluence site you are using.  You may set an environment variable (CONFLUENCE_BASE_URL) instead of supplying this value.

    .PARAMETER User
        The User of the confluence site you are using.  You may set an environment variable (CONFLUENCE_API_USER) instead of supplying this value.

    .PARAMETER ApiToken
        The API Token for the User of the confluence site you are using.  You may set an environment variable (CONFLUENCE_API_TOKEN) instead of supplying this value.

    .EXAMPLE
        Get-ConfluenceLabelStats.ps1 PSIT c:\path\to\stats.csv -BaseUrl https://accruent.atlassian.net/ -User user@accruent.com -ApiToken MyApiToken

    .NOTES
        In order to use this, you must have an API token for your Atlassian account.  Instructions for configuring an API token can be found at https://confluence.atlassian.com/cloud/api-tokens-938839638.html

        Adding the following environment variables shortens the commands considerably
            - CONFLUENCE_BASE_URL - https://accruent.atlassian.net/
            - CONFLUENCE_API_USER - user@accruent.com
            - CONFLUENCE_API_TOKEN - MyApiToken
#>

param(
    [Parameter(Position=1, Mandatory)]
    [System.String] $Space,

    [Parameter(Position=2)]
    [System.String] $OutputFile = $null,

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

$totalPageSearchUri = "$($BaseUrl)wiki/rest/api/search?cql=space%3D$($Space)%20and%20type%3Dpage"
$totalPageResults = Invoke-RestMethod -Method GET -Uri "$totalPageSearchUri" -Headers $Headers

$totalPages = $totalPageResults.totalSize

$start=0
$processedPages=0
$batchSize=100

$labelHash = @{}

Write-Host "Collecting label statistics for $($totalPages) pages..."
Do {
    
    write-progress -activity "Processing results" -status "Processed $($processedPages)" -PercentComplete (($processedPages * 100) / $totalPages)
    $result = Invoke-RestMethod -Method GET -Uri "$($BaseUrl)wiki/rest/api/content?spaceKey=$($Space)&expand=metadata.labels&limit=$($batchSize)&start=$($start)" -Headers $Headers

    $start = $start + $batchSize

    $processedPages = $processedPages + $result.size

    foreach ($item in $result.results) {
        if ($item.metadata.labels.size -gt 0) {
            foreach ($label in $item.metadata.labels.results) {
                if ($null -eq $labelHash[$label.label]) {
                    $labelHash[$label.label] =0
                }
                
                $labelHash[$label.label]++;
            }
        }
    }

} WHILE ($result.size -eq $batchSize)

Write-Host "Total Pages = $($processedPages)"
Write-Host ($labelHash | Out-String)

if ([System.String]::IsNullOrWhiteSpace($OutputFile) -eq $false) {
    $labelHash.GetEnumerator() | ForEach-Object {new-object psobject -Property @{Label = $_.name;LabelCount=$_.value}} | Export-Csv $OutputFile -NoTypeInformation
    Write-Host "Wrote results to $($OutputFile)";
}




