<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID c8a2bfd0-3f94-4911-aa26-4daedd054668
    .FILENAME Get-DaikinControlInfo.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Get-DaikinControlInfo {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinControlInfo
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname,
        [switch]$Raw
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_control_info' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result -Raw:$Raw
        $Result
    }
}
#endregion


