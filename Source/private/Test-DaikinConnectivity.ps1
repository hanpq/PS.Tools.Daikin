<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 1af893cc-b4cb-4c01-869e-d5b1b004ffb3
    .FILENAME Test-DaikinConnectivity.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-04
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Test-DaikinConnectivity {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Test-DaikinConnectivity
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )

    BEGIN {
        if (-not (Assert-FunctionRequirements -InstalledModules 'NetTCPIP')) { break }
    }

    PROCESS {
        $SavedProgressPreference = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'
        try {
            if (Test-NetConnection -ComputerName $Hostname -InformationLevel Quiet -WarningAction SilentlyContinue) {
                return $true
            } else {
                return $false
            }
        } catch {
            Write-Error -Message 'Failed to check status of daikin device' -TargetObject $Hostname -ErrorRecord $_
        } finally {
            $global:ProgressPreference = $SavedProgressPreference
        }
    }

}
#endregion


