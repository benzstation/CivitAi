Function Invoke-CivitAiRestMethod {
    <#
    .SYNOPSIS

    Executes a Get method to the CivitAi Rest API.

    .DESCRIPTION

    Executes a Get method to the CivitAi Rest API.
    If provided, will use the API Key to authenticate the execution.

    .PARAMETER uri
    Specifies the Rest API uri.

    .PARAMETER apikey
    Specifies the API Key to use.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the Rest API call result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Invoke-CivitAiRestMethod -uri 'https://civitai.com/api/v1/creators?&limit=1'
    Returns a single CivitAi model creator using an unauthenticated call

    .EXAMPLE

    PS> Invoke-CivitAiRestMethod -uri 'https://civitai.com/api/v1/models?&limit=1&favorites=true' -apikey '..ewgr0983wt...'
    Returns a single CivitAi favorite model using an authenticated call

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
        #Sometimes the API returns a malformed JSON because keys values case or empty keys name
        #Using Invoke-WebRequest instead of Invoke-RestMethod to capture the RawContentStream and encode it as an UTF-8 String.
        #This allows the code to fix key name and values and Convert it from a JSON string to a PSCustomObject
        #The list of items to replace will need to be maintained over time as new malformed data may get added in the future
        $webresult = Invoke-WebRequest @RestMethodArgs
        $utf8stringresult = [Text.Encoding]::UTF8.GetString($webresult.RawContentStream.ToArray())
        $result = $utf8stringresult.replace('NG_DeepNegative_V1_75T',('NG_DeepNegative_V1_75T'.ToLower())).replace('Prompt',('Prompt'.ToLower())).replace('Mode','mode').replace('Scale','scale').replace('""','"buggykey"').replace('EasyNegative','easynegative').replace('Resources','resources').replace('Size','size').replace('Resize','resize').replace('SiofraCipher',('siofraCipher'.ToLower())).replace('MaisieWilliams',('MaisieWilliams'.ToLower())).replace('type=model','type=Model') | ConvertFrom-Json
    }
    Catch {
        throw $PSItem
    }

    #retun the result
    return $result
}

Function Get-CivitAiCreators {
    <#
    .SYNOPSIS

    Gets list of CivitAi creators.

    .DESCRIPTION

    Gets list of CivitAi creators and their information.
    Can query a specify creator and its information.

    .PARAMETER limit
    The number of results to be returned per page. This can be a number between 0 and 200. By default, each page will return 20 results. If set to 0, it'll return all the items.

    .PARAMETER page
    The page from which to start fetching items.

    .PARAMETER query
    Search query to filter creators by username.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiCreators -limit 20 -page 2 
    Returns second page of 20 CivitAi model creators (21st-40th creators) and their information

    .EXAMPLE

    PS> Get-CivitAiCreators -query civitaiuser
    Returns the creator's information

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
    <#
    .SYNOPSIS

    Gets list of CivitAi Images.

    .DESCRIPTION

    Gets list of CivitAi Images and their information.
    Can query a specify Images and its information.

    .PARAMETER limit
    The number of results to be returned per page. This can be a number between 0 and 200. By default, each page will return 20 results. If set to 0, it'll return all the items

    .PARAMETER postId
    The ID of a post to get images from.

    .PARAMETER modelId
    The ID of a model to get images from (model gallery).

    .PARAMETER modelVersionId
    The ID of a model version to get images from (model gallery filtered to version).

    .PARAMETER username
    Filter to images from a specific user.

    .PARAMETER nsfw
    Filter to images that contain mature content flags or not (undefined returns all).

    .PARAMETER sort
    The order in which you wish to sort the results.

    .PARAMETER period
    The time frame in which the images will be sorted

    .PARAMETER page
    The page from which to start fetching items.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiImages -limit 20 -page 2 
    Returns second page of 20 CivitAi model images (21st-40th images) and their information

    .EXAMPLE

    PS> Get-CivitAiImages -username civitaiuser -model 8552
    Returns the images from use civitaiuser using any version of the model 8552

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
    <#
    .SYNOPSIS

    Gets list of CivitAi models.

    .DESCRIPTION

    Gets list of CivitAi models and their information.
    Can query a specify models and its information.

    .PARAMETER limit
    The number of results to be returned per page. This can be a number between 0 and 200. By default, each page will return 20 results. If set to 0, it'll return all the items

    .PARAMETER page
    The page from which to start fetching items.

    .PARAMETER tag
    Search query to filter models by tag

    .PARAMETER username
    Search query to filter models by user

    .PARAMETER types
    The type of model you want to filter with. If none is specified, it will return all types

    .PARAMETER sort
    The order in which you wish to sort the results

    .PARAMETER period
    The time frame in which the models will be sorted

    .PARAMETER rating
    The rating you wish to filter the models with. If none is specified, it will return models with any rating

    .PARAMETER favorites
    Filter to favorites of the authenticated user (this requires an API token or session cookie)

    .PARAMETER hidden
    Filter to hidden models of the authenticated user (this requires an API token or session cookie)

    .PARAMETER primaryFileOnly
    Only include the primary file for each model (This will use your preferred format options if you use an API token or session cookie)

    .PARAMETER allowNoCredit
    Filter to models that require or don't require crediting the creator

    .PARAMETER allowDerivatives
    Filter to models that allow or don't allow creating derivatives

    .PARAMETER allowDifferentLicenses
    Filter to models that allow or don't allow derivatives to have a different license

    .PARAMETER allowCommercialUse
    Filter to models based on their commercial permissions

    .PARAMETER nsfw
    If false, will return safer images and hide models that don't have safe images

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiModels -limit 20 -page 2 
    Returns second page of 20 CivitAi models (21st-40th models) and their information

    .EXAMPLE

    PS> Get-CivitAiModels -tag car
    Returns the models with tag car.

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
    <#
    .SYNOPSIS

    Gets a CivitAi models by its Id.

    .DESCRIPTION

    Gets a CivitAi model, by its Id, and its information.

    .PARAMETER modelId
    The ID of a model to information from.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiModelById -modelId 8552
    Returns the information from all versions of the model 8552

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
    <#
    .SYNOPSIS

    Gets a CivitAi model version by its Id.

    .DESCRIPTION

    Gets a CivitAi model version, by its Id, and its information.

    .PARAMETER modelId
    The ID of a model version to get information from.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiModelByVersionId -modelId 10081
    Returns the information of the model version 10081

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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
    <#
    .SYNOPSIS

    Gets list of CivitAi tags.

    .DESCRIPTION

    Gets list of CivitAi tags and their information.
    Can query a specify tag and its information.

    .PARAMETER limit
    The number of results to be returned per page. This can be a number between 0 and 200. By default, each page will return 20 results. If set to 0, it'll return all the items.

    .PARAMETER page
    The page from which to start fetching items.

    .PARAMETER query
    Search query to filter tags by name.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Get-CivitAiTags -limit 20 -page 2 
    Returns second page of 20 CivitAi model tags (21st-40th creators) and their information

    .EXAMPLE

    PS> Get-CivitAiTags -query car
    Returns the tag's information

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

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

Function Invoke-CivitAiModelDownload {
    <#
    .SYNOPSIS

    Downloads a CivitAi file.

    .DESCRIPTION

    Downloads a CivitAi file and store it locally.
    
    .PARAMETER uri
    Specifies the Rest API Download uri.

    .PARAMETER path
    Specifies the local full path name, include file name and extension, to store the downloaded file.

    .INPUTS

    None. You cannot pipe objects.

    .OUTPUTS

    PSCustomObject. It returns a PSCustomObject that includes the command result, including the metadata and any item(s) returned.

    .EXAMPLE

    PS> Invoke-CivitAiModelDownload -uri 'https://civitai.com/api/download/models/10081' -path 'C:\sd\checkpoint\dvarchMultiPrompt_dvarchExterior.safetensors'
    Downloads the model safetensors file.

    .EXAMPLE

    PS> Invoke-CivitAiModelDownload -uri 'https://image.civitai.com/xG1nkqKTMzGDvpLrqFT7WA/ceb881d2-fc45-4876-b84a-b718470dbe00/00055-1065154782.jpeg' -path 'C:\sd\checkpoint\dvarchMultiPrompt_dvarchExterior.jpg'
    Downloads the model's showcase jpg file.

    .LINK

    https://github.com/benzstation/CivitAi/
    #>

    param(
        [Parameter(Mandatory = $true)]
        [string]$uri,

        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $false)]
        [string]$apikey
    )

    #Defining header; for the API to return downloaded file's filename proper need the content-disposition set
    $headers = @{
        'Content-Disposition' = "attachment"
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
        OutFile = $path
    }

    #Call the API
    Try {
        $result = Invoke-RestMethod @RestMethodArgs
    }
    Catch {
        throw $PSItem
    }

    #retun the result
    return $result
}