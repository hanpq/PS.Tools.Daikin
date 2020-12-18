<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 95448aa4-5d64-4d68-a34f-4b699887dac2
    .FILENAME Get-DaikinPollingConfiguration.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, Hannes Palmquist, All Rights Reserved
#>
function Get-DaikinPollingConfiguration {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinPollingConfiguration
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}//common/get_remote_method' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


