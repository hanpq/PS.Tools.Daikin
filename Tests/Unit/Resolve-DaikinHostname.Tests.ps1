BeforeAll {
    . (Resolve-Path -Path "$PSScriptRoot\..\..\Source\private\Resolve-DaikinHostname.ps1")
}

Describe -Name "Resolve-DaikinHostname.ps1" -Fixture {
    BeforeAll {
        function Assert-FunctionRequirements {}
        Mock Assert-FunctionRequirements -MockWith { return $true }
    }
    Context -Name 'When calling with a valid FQDN that responds' {
        BeforeAll {
            function Test-DaikinConnectivity {}
            Mock Test-DaikinConnectivity -MockWith { return $true }
            Mock Test-NetConnection -MockWith {
                [pscustomobject]@{
                    remoteaddress = '192.168.1.1'
                }
            }
        }
        It -Name 'It should not throw' {
            {Resolve-DaikinHostname -Hostname 'daikin.network.com'} | should -not -throw
        }
        It -Name 'It should return 192.168.1.1' -Test {
            Resolve-DaikinHostname -HostName 'daikin.network.com' | should -be '192.168.1.1'
        }
    }
    Context -Name 'When calling with a valid FQDN that does not respond' {
        BeforeAll {
            function Test-DaikinConnectivity {}
            Mock Test-DaikinConnectivity -MockWith { return $false }
        }
        It -Name 'It should throw' {
            { Resolve-DaikinHostname -Hostname 'daikin.network.com' } | should -throw
        }
    }
}
