<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 1ccb5ae4-75de-4486-b550-8d67ed4d9359
    .FILENAME Get-DaikinYearStats.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Get-DaikinYearStats {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinYearStats
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_year_power' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


