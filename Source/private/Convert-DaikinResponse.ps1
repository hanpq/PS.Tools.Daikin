<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 97f6f35a-bf9b-4f28-84fe-9181732a2d24
    .FILENAME Convert-DaikinResponse.ps1
    .AUTHOR Hannes Palmquist
    .AUTHOREMAIL hannes.palmquist@outlook.com
    .CREATEDDATE 2020-10-03
    .COMPANYNAME Personal
    .COPYRIGHT (c) 2020, Hannes Palmquist, All Rights Reserved
#>
function Convert-DaikinResponse {
    <#
    .DESCRIPTION
        asd
    .PARAMETER Name
        Description
    .EXAMPLE
        Convert-DaikinResponse
        Description of example
    #>

    [CmdletBinding()] # Enabled advanced function support
    param(
        $String,
        [switch]$Raw
    )

    BEGIN {        
        $Translation = @{
            'id'       = 'Identity'
            'pow'      = 'PowerOn'
            'type'     = 'DeviceType'
            'reg'      = 'Region'
            'ver'      = 'Version'
            'rev'      = 'Revision'
            'err'      = 'Error'
            'pw'       = 'Password'
            'led'      = 'LED_Enabled'
            'grp_name' = 'GroupName'
            'location' = 'Location'
            'stemp'    = 'TargetTemp'
            'htemp'    = 'InsideTemp'
            'otemp'    = 'OutsideTemp'
            'hhum'     = 'InsideHumidity'
            'mode'     = 'Mode'
            'f_rate'   = 'FanSpeed'
            'f_dir'    = 'FanDirection'
            'shum'     = 'TargetHumidity'
            'dh1'      = 'Mem_AUTO_TargetHumidity'
            'dh2'      = 'Mem_DEHUMDIFICATOR_TargetHumidity'
            'dh3'      = 'Mem_COLD_TargetHumidity'
            'dh4'      = 'Mem_HEAT_TargetHumidity'
            'dh5'      = 'Mem_FAN_TargetHumidity'
            'dh7'      = 'Mem_AUTO_TargetHumidity'
            'dt1'      = 'Mem_AUTO_TargetTemp'
            'dt2'      = 'Mem_DEHUMDIFICATOR_TargetTemp'
            'dt3'      = 'Mem_COLD_TargetTemp'
            'dt4'      = 'Mem_HEAT_TargetTemp'
            'dt5'      = 'Mem_FAN_TargetTemp'
            'dt7'      = 'Mem_AUTO_TargetTemp'
        }
    }

    PROCESS {
        $Hash = [ordered]@{}
        $String.Split(',') | foreach-object {
            $Property = $PSItem.Split('=')[0]
            $Value = $PSItem.Split('=')[1]

            if (-not $Raw) {
                # Translate keys
                if ($Translation.ContainsKey($Property)) {
                    $Property = $Translation[$Property]    
                }
            
                switch ($Property) {
                    { @('PowerOn') -contains $PSItem } {
                        $Value = [bool][int]$Value
                    }
                    'Mode' {
                        switch ($Value) {
                            { 0, 1, 7 -contains $PSItem } { $Value = 'AUTO' }
                            2 { $Value = 'DRY' }
                            3 { $Value = 'COLD' }
                            4 { $Value = 'HEAT' }
                            6 { $Value = 'FAN' }
                        }
                    }
                    'FanSpeed' {
                        switch ($Value) {
                            'A' { $Value = 'AUTO' }
                            'B' { $Value = 'SILENT' }
                            '3' { $Value = 'Level_1' }
                            '4' { $Value = 'Level_2' }
                            '5' { $Value = 'Level_3' }
                            '6' { $Value = 'Level_4' }
                            '7' { $Value = 'Level_5' }
                        }
                    }
                    'FanDirection' {
                        switch ($Value) {
                            '0' { $Value = 'Stopped' }
                            '1' { $Value = 'VerticalSwing' }
                            '2' { $Value = 'HorizontalSwing' }
                            '3' { $Value = 'BothSwing' }
                        }
                    }
                }
            }            
            $Hash.$Property = $Value
        }
        $Hash
    }
}
#endregion