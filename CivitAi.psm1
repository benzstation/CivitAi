Function Invoke-CivitAiRestMethod {
    param(
        [Parameter(Mandatory = $true)]
        [string]$uri,

        [Parameter(Mandatory = $false)]
        [string]$apikey
    )

    #Defining header; for the API to return downloaded file's filename proper need the content-disposition set
    $headers = @{
        'Content-Disposition' = "inline"
    }

    #Adding API Key to the splatting hash if present
    If ($apikey) {
        $headers.Add('Authorization',"Bearer $apikey")
    }
    
    #Splatting arguments
    $RestMethodArgs = @{
        Headers = $headers
        Method = 'Get'
        Uri = $uri
        ContentType = 'application/json'
    }

    #Call the API
    Try {
        $result = Invoke-RestMethod @RestMethodArgs

        #Sometimes API returns a malformed JSON because keys values case aren't consistent and PowerShell detects the type as String instead of an Object
        #Replacing known values to lower case
        If ($result.GetType().name -eq 'string') {
            $result = $result.replace('Model','model').replace('Scale','scale').replace('""','"buggykey"').replace('embed:EasyNegative','embed:easynegative').replace('Resources','resources') | ConvertFrom-Json
        }
    }
    Catch {
        throw $PSItem
    }

    #retun the result
    return $result
}

Function Get-CivitAiCreators {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 200)]
        [int]$limit,

        [Parameter(Mandatory = $false)]
        [int]$page,

        [Parameter(Mandatory = $false)]
        [string]$query
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/creators'
    If ($PSBoundParameters.Values) {
        $uri = $uri + "?"
    }

    #Append base URI with parameters
    ForEach ($Parameter in $PSBoundParameters.Keys) {
        $Value = $PSBoundParameters[$Parameter]
        $uri = $uri + "&$Parameter=$Value"
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod -uri $uri

    #retun the result
    return $result
}

Function Get-CivitAiImages {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 200)]
        [int]$limit,

        [Parameter(Mandatory = $false)]
        [int]$postId,

        [Parameter(Mandatory = $false)]
        [int]$modelId,

        [Parameter(Mandatory = $false)]
        [int]$modelVersionId,

        [Parameter(Mandatory = $false)]
        [string]$username,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Soft', 'Mature', 'X')]
        [string]$nsfw,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Most Reactions', 'Most Comments', 'Newest')]
        [string[]]$sort,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AllTime', 'Year', 'Month', 'Week', 'Day')]
        [string[]]$period,

        [Parameter(Mandatory = $false)]
        [int]$page
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/images'
    If ($PSBoundParameters.Values) {
        $uri = $uri + "?"
    }

    ForEach ($Parameter in $PSBoundParameters.Keys) {
        $Value = $PSBoundParameters[$Parameter]
        $uri = $uri + "&$Parameter=$Value"
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod -uri $uri

    #retun the result
    return $result
}

function Get-CivitAiModels {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 200)]
        [int]$limit,

        [Parameter(Mandatory = $false)]
        [int]$page,

        [Parameter(Mandatory = $false)]
        [string]$query,

        [Parameter(Mandatory = $false)]
        [string]$tag,

        [Parameter(Mandatory = $false)]
        [string]$username,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Checkpoint', 'TextualInversion', 'Hypernetwork', 'AestheticGradient', 'LORA', 'Controlnet', 'Poses')]
        [string[]]$types,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Most Reactions', 'Most Comments', 'Newest')]
        [string[]]$sort,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AllTime', 'Year', 'Month', 'Week', 'Day')]
        [string[]]$period,

        [Parameter(Mandatory = $false)]
        [int]$rating,

        [Parameter(Mandatory = $false)]
        [bool]$primaryFileOnly,

        [Parameter(Mandatory = $false)]
        [bool]$favorites,

        [Parameter(Mandatory = $false)]
        [bool]$hidden,

        [Parameter(Mandatory = $false)]
        [bool]$allowNoCredit,

        [Parameter(Mandatory = $false)]
        [bool]$allowDerivatives,

        [Parameter(Mandatory = $false)]
        [bool]$allowDifferentLicenses,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Image', 'Rent', 'Sell')]
        [string[]]$allowCommercialUse,

        [Parameter(Mandatory = $false)]
        [bool]$nsfw,

        [Parameter(Mandatory = $false)]
        [string]$apikey
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/models'
    If ($PSBoundParameters.Values) {
        $uri = $uri + "?"
    }

    ForEach ($Parameter in $PSBoundParameters.Keys) {
        $Value = $PSBoundParameters[$Parameter]
        $uri = $uri + "&$Parameter=$Value"
    }    
    
    #Splatting arguments
    $RestMethodArgs = @{
        Uri = $uri
    }

    #Adding API Key to the splatting hash if present
    If ($apikey) {
        $RestMethodArgs.Add('apikey',$apikey)
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod @RestMethodArgs

    #retun the result
    return $result
}

function Get-CivitAiModelById {
    param(
        [Parameter(Mandatory = $true)]
        [int]$modelId
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/models'
    $uri = $uri + '/' + $modelId
    
    #Splatting arguments
    $RestMethodArgs = @{
        Uri = $uri
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod @RestMethodArgs

    #retun the result
    return $result
}

function Get-CivitAiModelByVersionId {
    param(
        [Parameter(Mandatory = $true)]
        [int]$modelVersionId
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/model-versions'
    $uri = $uri + '/' + $modelVersionId
    
    #Splatting arguments
    $RestMethodArgs = @{
        Uri = $uri
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod @RestMethodArgs

    #retun the result
    return $result
}

function Get-CivitAiTags {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 200)]
        [int]$limit,

        [Parameter(Mandatory = $false)]
        [int]$page,

        [Parameter(Mandatory = $false)]
        [string]$query
    )

    #Build base URI
    $uri = 'https://civitai.com/api/v1/tags'
    If ($PSBoundParameters.Values) {
        $uri = $uri + "?"
    }

    #Append base URI with parameters
    ForEach ($Parameter in $PSBoundParameters.Keys) {
        $Value = $PSBoundParameters[$Parameter]
        $uri = $uri + "&$Parameter=$Value"
    }

    #Call the API
    $result = Invoke-CivitAiRestMethod -uri $uri

    #retun the result
    return $result
}