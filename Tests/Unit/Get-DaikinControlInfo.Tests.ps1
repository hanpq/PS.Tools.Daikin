BeforeAll {
    . (Resolve-Path -Path "$PSScriptRoot\..\..\Source\private\Get-DaikinControlInfo.ps1")
}

Describe -Name "Get-DaikinControlInfo.ps1" -Fixture {
    BeforeAll {
    }
    Context -Name 'When retreival succeeds' {
        BeforeAll {
            Mock Invoke-RestMethod -MockWith {
                return 'ret=OK,pow=1,mode=7,adv=,stemp=22.0,shum=0,dt1=22.0,dt2=M,dt3=25.0,dt4=10.0,dt5=10.0,dt7=22.0,dh1=0,dh2=50,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=7,b_stemp=22.0,b_shum=0,alert=255,f_rate=A,f_dir=0,b_f_rate=A,b_f_dir=0,dfr1=A,dfr2=5,dfr3=5,dfr4=A,dfr5=A,dfr6=5,dfr7=A,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0'
            }
            function Convert-DaikinResponse {}
            Mock Convert-DaikinResponse -MockWith {
                return [ordered]@{
                    ret                               = "OK"
                    PowerOn                           = "True"
                    Mode                              = "AUTO"
                    adv                               = ""
                    TargetTemp                        = "22.0"
                    TargetHumidity                    = "0"
                    Mem_AUTO_TargetTemp               = "22.0"
                    Mem_DEHUMDIFICATOR_TargetTemp     = "M"
                    Mem_COLD_TargetTemp               = "25.0"
                    Mem_HEAT_TargetTemp               = "10.0"
                    Mem_FAN_TargetTemp                = "10.0"
                    Mem_AUTO_TargetHumidity           = "0"
                    Mem_DEHUMDIFICATOR_TargetHumidity = "50"
                    Mem_COLD_TargetHumidity           = "0"
                    Mem_HEAT_TargetHumidity           = "0"
                    Mem_FAN_TargetHumidity            = "0"
                    dhh                               = "50"
                    b_mode                            = "7"
                    b_stemp                           = "22.0"
                    b_shum                            = "0"
                    alert                             = "255"
                    FanSpeed                          = "AUTO"
                    FanDirection                      = "Stopped"
                    b_f_rate                          = "A"
                    b_f_dir                           = "0"
                    dfr1                              = "A"
                    dfr2                              = "5"
                    dfr3                              = "5"
                    dfr4                              = "A"
                    dfr5                              = "A"
                    dfr6                              = "5"
                    dfr7                              = "A"
                    dfrh                              = "5"
                    dfd1                              = "0"
                    dfd2                              = "0"
                    dfd3                              = "0"
                    dfd4                              = "0"
                    dfd5                              = "0"
                    dfd6                              = "0"
                    dfd7                              = "0"
                    dfdh                              = "0"
                    dmnd_run                          = "0"
                    en_demand                         = "0"                    
                }
            }
        }
        It -Name 'Should not throw' {
            { Get-DaikinControlInfo -Hostname "daikin.network.com" } | should -not -throw
        }
        It -Name 'Should return a hashtable' {
            Get-DaikinControlInfo -hostname 'daikin.network.com' | should -beoftype [System.Collections.Specialized.OrderedDictionary]
        }
        It -name 'Should return hashtable with keycount 43' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Keys | should -havecount 43
        }
        It -Name 'Should have readable property names' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Keys | should -contain 'TargetTemp'
        }
        It -Name 'Should have mode translated from int to string' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Mode | should -be 'AUTO'
        }
    }
    Context -Name 'When retreival succeeds and raw is requested' {
        BeforeAll {
            Mock Invoke-RestMethod -MockWith {
                return 'ret=OK,pow=1,mode=7,adv=,stemp=22.0,shum=0,dt1=22.0,dt2=M,dt3=25.0,dt4=10.0,dt5=10.0,dt7=22.0,dh1=0,dh2=50,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=7,b_stemp=22.0,b_shum=0,alert=255,f_rate=A,f_dir=0,b_f_rate=A,b_f_dir=0,dfr1=A,dfr2=5,dfr3=5,dfr4=A,dfr5=A,dfr6=5,dfr7=A,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0'
            }
            function Convert-DaikinResponse {}
            Mock Convert-DaikinResponse -MockWith {
                return [ordered]@{
                    ret       = "OK"
                    pow       = "1"
                    mode      = "7"
                    adv       = ""
                    stemp     = "22.0"
                    shum      = "0"
                    dt1       = "22.0"
                    dt2       = "M"
                    dt3       = "25.0"
                    dt4       = "10.0"
                    dt5       = "10.0"
                    dt7       = "22.0"
                    dh1       = "0"
                    dh2       = "50"
                    dh3       = "0"
                    dh4       = "0"
                    dh5       = "0"
                    dh7       = "0"
                    dhh       = "50"
                    b_mode    = "7"
                    b_stemp   = "22.0"
                    b_shum    = "0"
                    alert     = "255"
                    f_rate    = "A"
                    f_dir     = "0"
                    b_f_rate  = "A"
                    b_f_dir   = "0"
                    dfr1      = "A"
                    dfr2      = "5"
                    dfr3      = "5"
                    dfr4      = "A"
                    dfr5      = "A"
                    dfr6      = "5"
                    dfr7      = "A"
                    dfrh      = "5"
                    dfd1      = "0"
                    dfd2      = "0"
                    dfd3      = "0"
                    dfd4      = "0"
                    dfd5      = "0"
                    dfd6      = "0"
                    dfd7      = "0"
                    dfdh      = "0"
                    dmnd_run  = "0"
                    en_demand = "0"
                }
            }
        }
        It -Name 'Should not throw' {
            { Get-DaikinControlInfo -Hostname "daikin.network.com" } | should -not -throw
        }
        It -Name 'Should return a hashtable' {
            Get-DaikinControlInfo -hostname 'daikin.network.com' | should -beoftype [System.Collections.Specialized.OrderedDictionary]
        }
        It -name 'Should return hashtable with keycount 45' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Keys | should -havecount 45
        }
        It -Name 'Should have readable property names' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Keys | should -contain 'stemp'
        }
        It -Name 'Should not have mode translated from int to string' {
            (Get-DaikinControlInfo -hostname 'daikin.network.com').Mode | should -be '7'
        }
    }
    Context -Name 'When Invoke-RestMethod fails' {
        BeforeAll {
            Mock Invoke-RestMethod -MockWith { throw }
        }
        It -Name 'Should throw' {
            { Get-DaikinControlInfo -Hostname "daikin.network.com" } | should -throw
        }
    }
    Context -Name 'When Convert-DaikinResponse fails' {
        BeforeAll {
            function Convert-DaikinResponse {}
            Mock Convert-DaikinResponse -MockWith { throw }
        }
        It -Name 'Should throw' {
            { Get-DaikinControlInfo -Hostname "daikin.network.com" } | should -throw
        }
    }
}
