<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 4e991d92-4899-4fdc-9a6c-fe9486518135
    .FILENAME Get-DaikinModelInfo.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, Hannes Palmquist, All Rights Reserved
#>
function Get-DaikinModelInfo {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinModelInfo
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_model_info' -f $Hostname) -Method GET
        $Result = Convert-DaikinResponse -String $Result
        $Result
    }
}
#endregion


