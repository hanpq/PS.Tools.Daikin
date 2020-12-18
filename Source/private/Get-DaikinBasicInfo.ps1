<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 5588fcbe-895e-4578-b1c3-9948bc62c746
    .FILENAME Get-DaikinBasicInfo.ps1
    .AUTHOR Hannes Palmquist
    .CREATEDDATE 2020-10-03
    .COMPANYNAME 
    .COPYRIGHT (c) 2020, Hannes Palmquist, All Rights Reserved
#>
function Get-DaikinBasicInfo {
    <#
    .DESCRIPTION
        Powershell Module to control a Daikin AirCon unit
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinBasicInfo
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/common/basic_info' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


