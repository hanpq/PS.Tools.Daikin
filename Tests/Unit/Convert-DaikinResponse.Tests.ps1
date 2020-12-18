BeforeAll {
    . (Resolve-Path -Path "$PSScriptRoot\..\..\Source\private\Convert-DaikinResponse.ps1")
}

Describe -Name "Convert-DaikinResponse.ps1" -Fixture {
    BeforeAll {
        $ResponseString = 'ret=OK,pow=1,mode=7,adv=,stemp=22.0,shum=0,dt1=22.0,dt2=M,dt3=25.0,dt4=10.0,dt5=10.0,dt7=22.0,dh1=0,dh2=50,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=7,b_stemp=22.0,b_shum=0,alert=255,f_rate=A,f_dir=0,b_f_rate=A,b_f_dir=0,dfr1=A,dfr2=5,dfr3=5,dfr4=A,dfr5=A,dfr6=5,dfr7=A,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0'
    }
    Context -Name 'When calling without raw' {        
        It -Name 'Should not throw' {
            {Convert-DaikinResponse -String $ResponseString} | should -not -throw
        }
        It -Name 'Should return a ordered dictionary' {
            Convert-DaikinResponse -String $ResponseString | should -beoftype [System.Collections.Specialized.OrderedDictionary]
        }
        It -Name 'Should have count of 45' {
            (Convert-DaikinResponse -String $ResponseString).Keys | should -HaveCount 45
        }
        It -Name 'Should have readable property names' {
            (Convert-DaikinResponse -String $ResponseString).Keys | should -contain 'TargetTemp'
        }
        It -Name 'Should have mode translated from int to string' {
            (Convert-DaikinResponse -String $ResponseString).Mode | should -be 'AUTO'
        }
    }
    Context -Name 'When calling with raw' {        
        It -Name 'Should not throw' {
            { Convert-DaikinResponse -String $ResponseString -Raw} | should -not -throw
        }
        It -Name 'Should return a ordered dictionary' {
            Convert-DaikinResponse -String $ResponseString -Raw | should -beoftype [System.Collections.Specialized.OrderedDictionary]
        }
        It -Name 'Should have count of 45' {
            (Convert-DaikinResponse -String $ResponseString -Raw).Keys | should -HaveCount 45
        }
        It -Name 'Should have readable property names' {
            (Convert-DaikinResponse -String $ResponseString -Raw).Keys | should -contain 'stemp'
        }
        It -Name 'Should have mode translated from int to string' {
            (Convert-DaikinResponse -String $ResponseString -Raw).Mode | should -be '7'
        }
    }
}
