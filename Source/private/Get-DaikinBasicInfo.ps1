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
        Retreives daikin basic info object
    .PARAMETER Hostname
        IP of device
    .EXAMPLE
        Get-DaikinBasicInfo -Hostname 192.168.1.1
        
        Returns the basic info response from the device
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $Hostname
    )
    PROCESS {
        try {
            $Result = Invoke-RestMethod -Uri ('http://{0}/common/basic_info' -f $Hostname) -Method GET -ErrorAction Stop
        } catch {
            throw 'Failed to invoke rest method'
        }

        try {
            $Result = Convert-DaikinResponse -String $Result -ErrorAction Stop
        } catch {
            throw 'Failed to convert daikin response'
        }

        return $Result
    }
}
#endregion


