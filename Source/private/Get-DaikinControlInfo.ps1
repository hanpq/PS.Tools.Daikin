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
        Retrevies daikin control info response and optionally converts it into a more readable format
    .PARAMETER Hostname
        IP of device
    .EXAMPLE
        Get-DaikinControlInfo -hostname daikin.network.com
        Returns the control info object converted to a readable format
    .EXAMPLE
        Get-DaikinControlInfo -hostname -daikin.network.com -raw
        Returns the control info object with as-is property names
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        [Parameter(Mandatory)]$Hostname,
        [switch]$Raw
    )
    PROCESS {
        try {
            $Result = Invoke-RestMethod -Uri ('http://{0}/aircon/get_control_info' -f $Hostname) -Method GET -ErrorAction Stop
        } catch {
            throw $_.exception.message
        }

        try {
            $Result = Convert-DaikinResponse -String $Result -Raw:$Raw -ErrorAction Stop
        } catch {
            throw $_.exception.message
        }
        
        return $Result
    }
}
#endregion


