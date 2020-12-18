BeforeAll {
    . (Resolve-Path -Path "$PSScriptRoot\..\..\Source\private\Test-DaikinConnectivity.ps1")
}

Describe -Name "Test-DaikinConnectivity.ps1" -Fixture {
    BeforeAll {
        function Assert-FunctionRequirements {}
        Mock Assert-FunctionRequirements -MockWith {return $true}
    }
    Context -Name 'When able to connect to device' {
        BeforeAll {
            Mock Test-NetConnection -MockWith {return $true}
        }
        It -Name 'Should not throw' {
            {Test-DaikinConnectivity -Hostname 'daikin.network.com'} | should -not -throw
        }
        It -Name 'Return true' {
            Test-DaikinConnectivity -Hostname 'daikin.network.com' | should -BeTrue
        }
    }
    Context -Name 'When unable to connect to device' {
        BeforeAll {
            Mock Test-NetConnection -MockWith { return $false }
        }
        It -Name 'Should not throw' {
            { Test-DaikinConnectivity -Hostname 'daikin.network.com' } | should -not -throw
        }
        It -Name 'Return false' {
            Test-DaikinConnectivity -Hostname 'daikin.network.com' | should -befalse
        }
    }
    Context -Name 'When Test-NetConnection throws' {
        BeforeAll {
            Mock Test-NetConnection -MockWith { throw }
        }
        It -Name 'Should not throw' {
            { Test-DaikinConnectivity -Hostname 'daikin.network.com' } | should -throw
        }
    }
}
