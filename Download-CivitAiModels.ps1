<#
.SYNOPSIS

Downloads CivitAi Model(s).

.DESCRIPTION

Downloads CivitAi Model(s).
Use various switches to download models with specific tag or created by a specific creator and-or using filters.

.PARAMETER tag
Search query to filter-in models with a specific tag.

.PARAMETER creator
Search query to filter-in models done by a specific creators.

.PARAMETER outputDir
The output directory path to store models.

.PARAMETER outputNaming
The output files naming standard. Default uses filename from CivitAi and Custom uses the format 'BaseModel_CreatorName_ModelName_ModelVersionName' (Example: SD15_benzstation_HondaCivic_v10)

.PARAMETER excludeModelImage
Switch to skip the model image download - will only download model file without its companion image.

.PARAMETER exclusionWords
List of words to match Name or Tags for exclusion

.PARAMETER types
List of model types to download (Example: Checkpoint, LORA or TextualInversion)

.PARAMETER baseModels
List of base models to download (Example: SD 1.5 or SDXL 1.0)

.PARAMETER apikey
Specifies the API Key to use.

.INPUTS

None. You cannot pipe objects.

.OUTPUTS

Log Transcript & Downloaded files.

.EXAMPLE

PS> ."...\Download-CivitAiModels.ps1" -tag car -outputdir c:\sd\ -types TextualInversion, LORA -apikey '52d9...f30f83' -outputNaming Custom -exclusionWords 'Ferrari' -baseModels 'SD 1.5'
Downloads all LORA or TextualInversion SD 1.5 models with tag 'Car' excluding Ferrai and uses the provided API Key if authentication is required. Stores the download under C:\SD\ and use the custom naming scheme.

.EXAMPLE

PS> ."...\Download-CivitAiModels.ps1" -tag Buildings -outputdir c:\sd\ -types Checkpoint -apikey '52d9...f30f83' -exclusionWords 'Pixel Art' -baseModels 'SDXL 1.0'
Downloads all Checkpoint SDXL 1.0 models with tag 'Buildings' excluding 'Pixel Art' and uses the provided API Key if authentication is required. Stores the download under C:\SD\ and use the default naming scheme.

.LINK

https://github.com/benzstation/CivitAi/
#>

[CmdletBinding()]

Param (
    [Parameter(Mandatory = $true, ParameterSetName = "Tag")]
    [string]$tag,

    [Parameter(Mandatory = $true, ParameterSetName = "Creator")]
    [string]$creator,

    [Parameter(Mandatory = $true)]
    [string]$outputDir,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Default', 'Custom')]
    [string]$outputNaming = 'Default',

    [Parameter(Mandatory = $false)]
    [switch]$excludeModelImage,

    [Parameter(Mandatory = $false)]
    [string[]]$exclusionWords,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Checkpoint', 'TextualInversion', 'Hypernetwork', 'AestheticGradient', 'LORA', 'Controlnet', 'Poses')]
    [string[]]$types,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Other', 'SD 1.4', 'SD 1.5', 'SD 2.0', 'SD 2.0 768', 'SD 2.1', 'SD 2.1 768', 'SD 2.1 Unclip', 'SDXL 0.9', 'SDXL 1.0')]
    [string[]]$baseModels = ('SD 1.5'),

    [Parameter(Mandatory = $false)]
    [string]$apikey
)

Start-Transcript -OutputDirectory $PWD

Try {
    #count vars
    $totalmodels = 0
    $totalmodelswithexcludedtags = 0
    $totalmodelverionsforselectbasemodels = 0
    $totalmodelversionfiles = 0
    $totalmodelversionfilesalreadydownloaded = 0
    $totalmodelversionfileswithoutvalidextension = 0
    $totalmodelversionfileswithfailedscan = 0
    $totalmodelversionfileswithexcludedwords = 0
    $totalmodelversionfilesdownloaded = 0
    $totalmodelversionfilesnotfound = 0
    $totalmodelversionfilesdownloadrequiredauth = 0
    $totalmodelversionfilesdownloadfailedauth = 0
    $totalmodelversionfilesdownloadtimedout = 0
    $totalmodelversionimagefilesdownloaded = 0
    
    $typeLoopIndex = 1
    ForEach ($type in $types) {

        #Display process index and bump the count for next iteration
        "($typeLoopIndex of $($types.count)) $type process started"
        $typeLoopIndex++

        #Building the Model Query and querying
        $getCivitAiModelsArgs = @{
            limit = 0
            primaryFileOnly = $true
            types = $type
        }

        If ($tag) {
            $getCivitAiModelsArgs.Add('tag',$tag)
        }
        ElseIf ($creator) {
            $getCivitAiModelsArgs.Add('username',$creator)
        }

        "# Running the query"
        $result = Get-CivitAiModels @getCivitAiModelsArgs
        "# Done"

        If ($result.metadata.totalItems -eq 0) {
            "# No results"
        }

        #Processing each  model
        $modelLoopIndex = 1
        ForEach ($model in $result.items) {
            $totalmodels++

            #building few vars
            $modelName = $model.name
            $modelCreator = $model.creator.username
            $modelId = $model.id
            $modelVersions = $model.modelVersions
            $modelTags = $model.tags

            #Display process index and bump the count for next iteration
            "## ($modelLoopIndex of $($result.items.count)) $type $modelName process started"
            $modelLoopIndex++

            #Check if model tags include a word to exclude
            If ($exclusionWords) {
                $breakTheLoop = $false
                ForEach ($exclusionWord in $exclusionWords) {
                    If ($modelTags -contains $exclusionWord) {
                        $totalmodelswithexcludedtags++
                        $breakTheLoop = $true
                        break
                    }
                }
                If ($breakTheLoop) {
                    "### $modelName tags include an excluded word - skipping it"
                    continue
                }
            }

            #Filtering in only versions for selected basemodels
            "### Selecting in-scope model versions based on basemodels $($baseModels -join ',')"
            $inScopeModelversions = @()
            $inScopeModelversions += $modelVersions | Where-Object -FilterScript {$PSitem.baseModel -in $baseModels}
            "### Done"

            #Check if model tags include a word to exclude
            If ($inScopeModelversions.count -eq 0) {
                "### no versions matching selected base models"
                continue
            }
            
            #Filtering in only versions for selected modelversions
            "### Found $($inScopeModelversions.count) in-scope version(s)"

            #Processing each version
            $versionLoopIndex = 1
            ForEach ($modelVersion in $inScopeModelversions) {
                $totalmodelverionsforselectbasemodels++

                #building few vars
                $modelVersionName = $modelVersion.name
                $modelVersionId = $modelVersion.id
                $modelVersionFiles = $modelVersion.files
                $modelVersionImageFileDownloadUrl = $modelVersion.images[0].url
                $modelVersionImageFileExtension = $modelVersionImageFileDownloadUrl.Split('.')[-1]
                Switch ($outputNaming) {
                    Default {
                        $modelVersionImageFileName = $modelVersionFiles[0].name.Split('.')[0]
                    }
                    Custom {
                        $modelVersionBaseModelCustomName = $modelVersion.basemodel -replace "[^a-zA-Z0-9_]", ''
                        $modelCreatorCustomName = $modelCreator -replace "[^a-zA-Z0-9_]", ''
                        $modelNameCustomName = $modelName -replace "[^a-zA-Z0-9_]", ''
                        $modelVersionCustomName = $modelVersionName -replace "[^a-zA-Z0-9_]", ''
                        $modelVersionImageFileName = @($modelVersionBaseModelCustomName, $modelCreatorCustomName, $modelNameCustomName, $modelVersionCustomName) -join '_'
                        $modelVersionImageFilePath = "$outputDir\$type\$modelVersionImageFileName.$modelVersionImageFileExtension"
                    }
                }
                $modelVersionImageFilePath = "$outputDir\$type\$modelVersionImageFileName.$modelVersionImageFileExtension"

                #Display process index and bump the count for next iteration
                "#### ($versionLoopIndex of $($inScopeModelversions.count)) $type $modelName $modelVersionName process started"
                $versionLoopIndex++

                $fileLoopIndex = 1
                ForEach ($modelVersionFile in $modelVersionFiles) {
                    $totalmodelversionfiles++

                    #building few vars
                    $modelVersionFileName = $modelVersionFile.name
                    $modelVersionFileId = $modelVersionFile.id
                    $modelVersionFileDownloadUrl = $modelVersionFile.downloadUrl
                    Switch ($outputNaming) {
                        Default {
                            $modelVersionFilePath = "$outputDir\$type\$modelVersionFileName"
                        }
                        Custom {
                            $modelVersionFileExtension = $modelVersionFileName.Split('.')[-1]
                            $modelVersionFileCustomName = @($modelVersionBaseModelCustomName, $modelCreatorCustomName, $modelNameCustomName, $modelVersionCustomName) -join '_'
                            $modelVersionFilePath = "$outputDir\$type\$modelVersionFileCustomName.$modelVersionFileExtension"
                        }
                    }

                    #Display process index and bump the count for next iteration
                    "###### ($fileLoopIndex of $($modelVersionFiles.count)) $type $modelName $modelVersionName $modelVersionFileName process started"
                    $fileLoopIndex++

                    #Test if the file exists else download
                    If (Test-Path -Path $modelVersionFilePath) {
                        $totalmodelversionfilesalreadydownloaded++
                        "####### $type file $modelVersionFilePath already exists"
                        continue
                    }

                    #Checking if version has a PickleTensor or SafeTensor file extension.
                    If ($modelVersionFileName.Split('.')[-1] -notin ('pt','safetensors')) {
                        $totalmodelversionfileswithoutvalidextension++
                        "####### $type file $modelVersionFileName has an invalid file extension"
                        continue
                    }

                    #Checkinf file virus scan result
                    If ($modelVersionFile.virusScanResult -ne 'Success') {
                        $totalmodelversionfileswithfailedscan++
                        throw "####### $type file $modelVersionFileName has not succeeded the virus scan"
                        continue
                    }

                    #Checking if model version file name include a word to exclude
                    If ($exclusionWords) {
                        $breakTheLoop = $false
                        ForEach ($exclusionWord in $exclusionWords) {
                            If ($modelVersionFileName -match "\b$exclusionWord\b") {
                                $totalmodelversionfileswithexcludedwords++
                                "####### $modelVersionFileName include an excluded word - skipping it"
                                $breakTheLoop = $true
                            }
                        }
                        If ($breakTheLoop) {
                            continue
                        }
                    }

                    #API has random 500 errors - using a 3 retry loop
                    "####### Downloading Model Version file"
                    $retryCount = 3
                    While ($retryCount -gt 0) {
                        Try {
    
                            #Splatting arguments
                            $invokeCivitAiModelDownload = @{
                                uri = $modelVersionFileDownloadUrl
                                path = $modelVersionFilePath.Replace("[",'').Replace("]",'')
                            }
                            
                            #Adding API Key to the splatting hash if present
                            If ($authDownload) {
                                $invokeCivitAiModelDownload.Add('apikey', $apikey)
                            }

                            #Downloading model version file
                            $modelVersionFileDownloadResult = Invoke-CivitAiModelDownload @invokeCivitAiModelDownload
                            $totalmodelversionfilesdownloaded++
                            "####### Done"
                    

                            #Display process complete
                            "###### $type $modelName $modelVersionName $modelVersionFileName process completed"
                            "######"
                            $retryCount = 0
                            $authDownload = $false
                        }
                        Catch {
                            If ($PSItem.Exception.Message -match "404") {
                                Write-Error -Message "Model not found"
                                #Display process error
                                $totalmodelversionfilesnotfound++
                                "###### $type $modelName $modelVersionName $modelVersionFileName process errored out"
                                "######"
                                $retryCount = 0
                            }
                            ElseIf ($PSItem.Exception.Message -match "401") {
                                $totalmodelversionfilesdownloadrequiredauth++
                                If ($apikey) {
                                    $authDownload = $True
                                }
                                Else {
                                    #Display process requires auth
                                    $totalmodelversionfilesdownloadfailedauth++
                                    Write-Error -Message "$type $modelName $modelVersionName $modelVersionFileName process requires authentication - provide an API Key"
                                    $retryCount = 0
                                }
                            }
                            ElseIf ($retryCount -eq 1) {
                                #Display process timeout
                                $totalmodelversionfilesdownloadtimedout++
                                "###### $type $modelName $modelVersionName $modelVersionFileName process timed out"
                                throw $PSItem
                            }
                            Else {
                                $retryCount--
                            }
                        }
                    }
                }

                #Checking if the switch to skip image download is set
                If ($excludeModelImage) {
                    "##### Exclude image download switch is set - skipping it"
                    continue    
                }

                #Downloading first Image File
                "####### Downloading Model Version Image file"
                $modelVersionImageFileDownloadResult = Invoke-CivitAiModelDownload -uri $modelVersionImageFileDownloadUrl -path $modelVersionImageFilePath.Replace("[",'').Replace("]",'')
                $totalmodelversionimagefilesdownloaded++
                "####### Done"

                #Display process complete
                "#### $type $modelName $modelVersionName process completed"
                "####"
            }

            #Display process complete
            "## $type $modelName process completed"
            "##"
        }
        
        #Display process complete
        "$type process completed"
        "-"
    }

    #Display Stats
    "$totalmodels Total models processed"
    "$totalmodelswithexcludedtags Total models excluded because of an exclude tag"
    "$totalmodelverionsforselectbasemodels Total model versions processed"
    "$totalmodelversionfiles Total model version files processed"
    "$totalmodelversionfilesalreadydownloaded Total model version files were already downloaded"
    "$totalmodelversionfileswithoutvalidextension Total model version files had an invalid extension"
    "$totalmodelversionfileswithfailedscan Total model version files with a failed scan status"
    "$totalmodelversionfileswithexcludedwords Total model version filename excluded because of an exclude word"
    "$totalmodelversionfilesdownloaded Total model version files downloaded"
    "$totalmodelversionfilesnotfound Total model version files not found"
    "$totalmodelversionfilesdownloadrequiredauth Total model version files required authentication"
    "$totalmodelversionfilesdownloadfailedauth Total model version files downloaded failed authentication"
    "$totalmodelversionfilesdownloadtimedout Total model version files download timed out"
    "$totalmodelversionimagefilesdownloaded Total model version images downloaded"
}
Catch {
    throw $PSItem
}

Stop-Transcript