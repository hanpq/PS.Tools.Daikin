<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 3de2031d-875b-45d9-9463-6893a23d3345
    .FILENAME Get-DaikinWeekStats.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Get-DaikinWeekStats {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinWeekStats
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_week_power' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


