<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 6746c383-3590-4a42-b8e0-1a4134e6f216
    .FILENAME Set-DaikinAirCon.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, , All Rights Reserved
#>
function Set-DaikinAirCon {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Set-DaikinAirCon
        Description of example
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidInvokingEmptyMembers', '', Justification = 'asd')]
    [CmdletBinding()] # Enabled advanced function support
    param(
        $HostName,
        [boolean]$PowerOn,
        [ValidateRange(10, 41)][int]$Temp,
        [ValidateSet('AUTO', 'DRY', 'COLD', 'HEAT', 'FAN')]$Mode,
        [ValidateSet('AUTO', 'SILENT', 'Level_1', 'Level_2', 'Level_3', 'Level_4', 'Level_5')]$FanSpeed,
        [ValidateSet('Stopped', 'VerticalSwing', 'HorizontalSwing', 'BothSwing')]$FanDirection
    )

    BEGIN {
        $ModeTranslation = @{
            'AUTO' = '1'
            'DRY'  = '2'
            'COLD' = '3'
            'HEAT' = '4'
            'FAN'  = '6'
        }
        $FanSpeedTranslation = @{
            'AUTO'    = 'A'
            'SILENT'  = 'B'
            'Level_1' = 'lvl_1'
            'Level_2' = 'lvl_2'
            'Level_3' = 'lvl_3'
            'Level_4' = 'lvl_4'
            'Level_5' = 'lvl_5'

        } 
        $FanDirectionTranslation = @{
            'Stopped'         = '0'
            'VerticalSwing'   = '1'
            'HorizontalSwing' = '2'
            'BothSwing'       = '3'
        }

        $CurrentSettings = Get-DaikinControlInfo -Hostname:$Hostname -Raw
        $NewSettings = [ordered]@{
            'pow'    = $CurrentSettings.pow
            'mode'   = $CurrentSettings.mode
            'stemp'  = $CurrentSettings.stemp
            'shum'   = $CurrentSettings.shum
            'f_rate' = $CurrentSettings.f_rate
            'f_dir'  = $CurrentSettings.f_dir
        }
    }

    PROCESS {
        foreach ($Key in $PSBoundParameters.Keys) {
            if ($Key -eq 'HostName') { continue }
            switch ($Key) {
                'Temp' { $NewSettings.stemp = $PSBoundParameters.$Key }
                'PowerOn' { $NewSettings.pow = $PSBoundParameters.$Key }
                'Mode' { $NewSettings.mode = $ModeTranslation.($PSBoundParameters.$Key) }
                'FanSpeed' { $NewSetting.f_rate = $FanSpeedTranslation.($PSBoundParameters.$Key) }
                'FanDirection' { $NewSetting.f_dir = $FanDirectionTranslation.($PSBoundParameters.$Key) }
            }
        }
        if ($NewSettings.stemp -eq '--') {
            $NewSettings.stemp = $CurrentSettings.('dt{0}' -f $NewSettings.Mode)
        }
        if ($NewSettings.shum -eq '--') {
            $NewSettings.shum = $CurrentSettings.('dh{0}' -f $NewSettings.Mode)
        }
    }

    END {
        $String = @()
        foreach ($Key in $NewSettings.Keys) {
            $String += ('{0}={1}' -f $Key, $NewSettings.$Key)
        } 
        $PropertyString = $String -join '&'
    
        $URI = ('http://{0}/aircon/set_control_info?{1}' -f $HostName, $PropertyString)
        $Result = Invoke-RestMethod -Uri $uri -Method post
        $Result = Convert-DaikinResponse -String $Result

        switch ($Result.ret) {
            'OK' { Write-Success -Message 'Successfully sent command to AirCon' -Target $Hostname }
            'PARAM NG' { Write-Error -Message ('Command failed: [PARAM NG]') -TargetObject $Hostname }
            default { Write-Warning -Message ('Unknown message returned: {0}' -f $PSItem) -Target $HostName }
        } 
    }

}
#endregion


