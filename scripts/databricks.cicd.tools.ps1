<#
.SYNOPSIS
    -
.DESCRIPTION
    -
.EXAMPLE
    -
.INPUTS
    -
.OUTPUTS
    -
.NOTES
#>

# Parameter help description

param (
    [Parameter(Mandatory = $false)] [string] $authType,
    #bearer token
    [Parameter(Mandatory = $false)] [string] $region,
    [Parameter(Mandatory = $false)] [string] $bearerToken,
    #Service principal
    [Parameter(Mandatory = $false)] [string] $applicationId,
    [Parameter(Mandatory = $false)] [string] $secret,
    [Parameter(Mandatory = $false)] [string] $resourceGroup,
    [Parameter(Mandatory = $false)] [string] $subscriptionId,
    [Parameter(Mandatory = $false)] [string] $workSpaceName,
    [Parameter(Mandatory = $false)] [string] $tenantId,
    
    #what is apiUrl used here for? 
    [Parameter(Mandatory = $false)] [string] $apiUrl,
    #notebook parameters for deployment
    #switch to test databricks connection. - still under development
    [switch]$testDatabricksConnection,
    # Test. Argument -clusters ("a","b")
    # Databricks Library deployment. Needs a clusterID. Supports Array.
    [Parameter(Mandatory = $false)] [array] $clusterId
)
#Module Check
Write-Host 'Checking Module:'
Get-InstalledModule azure.databricks.cicd.tools
# Write-Host 'Module was found.'


if ($PSBoundParameters.ContainsKey('testDatabricksConnection')) {
    Write-Host "Connecting to Workspace to verify connection details are correct:"
    # Test-ConnectDatabricks
}

#Region----------------------------[Connect to Databricks]---------------------------------------#

function Connect-DatabricksInstance {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("token","sp")]
        # [ValidateScript({
        #     if ($_ -like "token"){
        #         write-host 'Entered the correct one'
        #     }
        # },
        # ErrorMessage = "{0} is ERROR"
        # )]
        [ValidateNotNullOrEmpty()]
        [string] $fpAuthType,
        [string] $fpRegion,
        [string] $fpBearerToken,
        #Service principal
        [string] $fpApplicationId,
        [string] $fpSecret,
        [string] $fpResourceGroup,
        [string] $fpSubscriptionId,
        [string] $fpWorkSpaceName,
        [string] $fpTenantId
    )
    begin {
        Write-Host 'Connecting to Databricks:'
    } 
    process {
        switch -Exact ($fpAuthType) {
            'token' { 
                Write-Host 'Connecting using Token' 
                #Bearer
                Connect-Databricks `
                    -BearerToken $fpBearerToken `
                    -Region $fpRegion
                Write-Host 'Successfully connected to Databricks using Bearer Token'
            }
            'sp' {
                Write-Host 'Conecting using Service Principal'
                #AAD SP
                Connect-Databricks `
                    -Region $fpRegion `
                    -ApplicationId $fpApplicationId `
                    -Secret $fpSecret `
                    -ResourceGroupName $fpResourceGroup `
                    -SubscriptionId $fpSubscriptionId `
                    -WorkspaceName $fpWorkSpaceName `
                    -tenantId $fpTenantId
                Write-Host 'Successfully connected to Databricks using Service Principal'
                
            }
            Default {
                Write-Host 'Exiting the Task, no Bearer Token or Service Principal was not found'
                exit
            }
        }
    }
    end {
        Write-Host 'Closing Function:Connect-DatabricksInstance'   
    }
}
#endregion

#Region----------------------------[Upload File]-------------------------------------------------#
function Add-DatabricksFiles {
    [CmdletBinding()]
    param (
        
    ) 
    begin {
        Write-Host 'Starting Function: Add-DatabricksFiles'
        $InformationPreference = 'Continue'
    } 
    process {
        $artifactSourceAlias = $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
        $workingDirPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
        
        #path for build artifact name
        $buildArtifactPath = Join-Path `
            -Path $workingDirPath `
            -ChildPath $artifactSourceAlias | join-path -ChildPath $artifactName
            
        $SourcePath = Join-Path `
            -Path $buildArtifactPath `
            -ChildPath 'source'
        
        Write-Host "Source Dir : $SourcePath"   

        Write-Information "Deploying the Velocity Databricks Source Code file."

       try {
                Add-DatabricksDBFSFile -LocalRootFolder $SourcePath -FilePattern "*.so" -TargetLocation '/sharedobjects/velocity_modules/' -Verbose -Debug
        }
        catch {
            Write-host $_.Exception.Message -ForegroundColor DarkRed
        }
    }
    end {    
        Write-Host "Closing Function: Add-DatabricksFiles "
    }
}
#endregion

####### Functions Calls #######

Connect-DatabricksInstance `
    -fpAuthType $authType `
    -fpRegion $region `
    -fpBearerToken $bearerToken `
    -fpApplicationId $applicationId `
    -fpSecret $secret `
    -fpResourceGroup $resourceGroup `
    -fpSubscriptionId $subscriptionId `
    -fpWorkSpaceName $workSpaceName `
    -fpTenantId $tenantId

Add-DatabricksFiles
