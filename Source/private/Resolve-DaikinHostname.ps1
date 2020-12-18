<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID c7cde592-51c5-4ee3-8ab4-ac50689629af
    .FILENAME Resolve-DaikinHostname.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-04
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Resolve-DaikinHostname {
    <#
    .DESCRIPTION
        Function tests connection to specified target
    .PARAMETER Hostname
        IP or FQDN for device
    .EXAMPLE
        Resolve-DaikinHostname -Hostname daikin.network.com
        Returns true or false depending on connection status
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        [Parameter(Mandatory)]$Hostname
    )
    PROCESS {
        if (-not (Assert-FunctionRequirements -InstalledModules 'NetTCPIP')) { break }
        $SavedProgressPreference = $global:progresspreference
        $Global:ProgressPreference = 'SilentlyContinue'
        if (Test-DaikinConnectivity -HostName:$Hostname) {
            return Test-NetConnection -ComputerName $Hostname -WarningAction SilentlyContinue | select-object -expand remoteaddress
        } else {
            throw "Device does not respond"
        }
    }
}
#endregion


