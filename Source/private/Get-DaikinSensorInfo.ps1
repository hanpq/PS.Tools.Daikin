<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID b442c29e-cabd-4a4a-8a43-2a331457b623
    .FILENAME Get-DaikinSensorInfo.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Get-DaikinSensorInfo {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinSensorInfo
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_sensor_info' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


