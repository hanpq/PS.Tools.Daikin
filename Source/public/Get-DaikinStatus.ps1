<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 63e0de6b-48a6-4a9b-9874-1a586f6c5ce4
    .FILENAME Get-DaikinStatus.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-04
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, Hannes Palmquist, All Rights Reserved
#>
function Get-DaikinStatus {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Get-DaikinStatus
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $HostName
    )

    BEGIN {
        $Hostname = Resolve-DaikinHostname -Hostname:$Hostname
        $ControlInfo = Get-DaikinControlInfo -Hostname:$HostName
        Write-Verbose -Message 'Collected ControlInfo via REST API' -target $hostname
        # $ModelInfo = Get-DaikinModelInfo -Hostname:$HostName
        # Write-Verbose -Message 'Collected ModelInfo via REST API' -target $hostname
        $BasicInfo = Get-DaikinBasicInfo -Hostname:$HostName
        Write-Verbose -Message 'Collected BasicInfo via REST API' -target $hostname
        $SensorInfo = Get-DaikinSensorInfo -HostName:$HostName
        Write-Verbose -Message 'Collected SensorInfo via REST API' -target $hostname
    }

    PROCESS {
        $ObjectHash = [ordered]@{
            'PowerOn'        = $ControlInfo.PowerOn
            'Mode'           = $ControlInfo.Mode
            'TargetTemp'     = $ControlInfo.TargetTemp
            'TargetHumidity' = $ControlInfo.TargetHumidity
            'FanSpeed'       = $ControlInfo.FanSpeed
            'FanDirection'   = $ControlInfo.FanDirection
            'InsideTemp'     = $SensorInfo.InsideTemp
            'InsideHumidity' = $SensorInfo.InsideHumidity
            'OutsideTemp'    = $SensorInfo.OutsideTemp
            'DeviceType'     = $BasicInfo.DeviceType
            'Region'         = $BasicInfo.Region
            'Version'        = $BasicInfo.Version.Replace('_', '.')
            'Revision'       = $BasicInfo.Revision
            'Port'           = $BasicInfo.port
            'Identity'       = $BasicInfo.Identity
            'MACAddress'     = $BasicInfo.mac
        }
        return [pscustomobject]$ObjectHash
    }
}
#endregion


