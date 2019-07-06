function Invoke-GhostApiCall {
    <#
        .SYNOPSIS
            Main function that all public-facing functions use to call the APIs.

        .PARAMETER Endpoint
            Mandatory parameter for the API endpoint. Available options can be found here: https://docs.ghost.org/api/content/#endpoints
        
        .PARAMETER Api
            Mandatory parameter that can be content or admin.

        .PARAMETER ApiUrl
            Optional parameter. If this isn't used, it's value will be attempted to be found in the configuration.json.
        
        .PARAMETER ApiKey
            Optional parameter. If this isn't used, it's value will be attempted to be found in the configuration.json.
    
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('content', 'admin')]
        [string]$Api,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiUrl = (Get-GhostConfiguration).ApiUrl,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey,

        [Parameter()]
        [hashtable]$Body,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Include,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Filter
    )

    $ErrorActionPreference = 'Stop'

    try {
        if (-not $PSBoundParameters.ContainsKey('ApiKey')) {
            switch ($Api) {
                'content' {
                    $ApiKey = (Get-GhostConfiguration).ContentApiKey
                    break
                }
                'admin' {
                    $ApiKey = (Get-GhostConfiguration).AdminApiKey
                    break
                }
                default {
                    throw "Unrecognized APIKey: [$_]"
                }
            }
        }
        $invParams = @{ }

        $request = [System.UriBuilder]"$ApiUrl/ghost/api/v2/$Api/$Endpoint"
        $queryParams = @{
            'key' = $ApiKey
        }
        if ($PSBoundParameters.ContainsKey('Include')) {
            $queryParams.Include = $Include -join ','
        }
        if ($PSBoundParameters.ContainsKey('Filter')) {
            $queryParams.Filter = New-Filter -Filter $Filter
        }

        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        foreach ($queryParam in $queryParams.GetEnumerator()) {
            $params[$queryParam.Key.ToLower()] = $queryParam.Value
        }
        $request.Query = $params.ToString()
        $invParams.Uri = $request.Uri

        if ($Body) {
            $invParams.Body = $Body
        }
        $stop = 'now'
        Invoke-RestMethod @invParams
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}