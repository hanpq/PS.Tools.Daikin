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
        Cmdlet allows to configure the aircon device to the desired setting.
    .PARAMETER Hostname
        Hostname or IP of the Daikin AirCon device.
    .PARAMETER PowerOn
        Set to $true or $false to specify if the master power should be on or off. This does not the affect the connectivity of the control surfice.
    .PARAMETER Temp
        Specified the target temperature in celcius.
    .PARAMETER Mode
        Specifies the operating mode of the aircon device. Allowed values are;
        AUTO  : Switches between heat and cold depending on the current and target temperature.
        DRY   : Sets the device lower the humidity of the air.
        COLD  : Sets the device chill the air if needed. No heat will be provided.
        HEAT  : Sets the device heat the air if needed. No chilling of air will be provided.
        FAN   : Sets the device to only circulate air without affecting temperature or humidity.
    .PARAMETER FanSpeed
        Specifies the strenght of the fan. Allowed values are;
        AUTO   : Sets the device to manage fan speed to keep the target climate.
        SILENT : Sets the fan speed to minimize noise.
        Level_1 -> Level_5 : Sets the fan speed to the target level.
    .PARAMETER FanDirection
        Specifies how the direction of airflow is controlled. Allowed values are
        Stopped, VerticalSwing, HorizontalSwing and BothSwing 
    .EXAMPLE
        Set-DaikinAirCon -HostName daikin.local.network -PowerOn:$true -Temp 19 -Mode AUTO -FanSpeed AUTO -FanDirection Stopped
        
        This example configures the aircon device to the specified parameter values.
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


