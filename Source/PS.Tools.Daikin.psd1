
@{
  RootModule = 'PS.Tools.Daikin.psm1'
  ModuleVersion = '1.0.2'
  CompatiblePSEditions = @('Desktop','Core')
  GUID = '5588fcbe-895e-4578-b1c3-9948bc62c746'
  Author = 'Hannes Palmquist'
  CompanyName = ''
  Copyright = '(c) 2020 Hannes Palmquist. All rights reserved.'
  Description = 'Powershell Module to control a Daikin AirCon unit'
  RequiredModules = @()
  FunctionsToExport = @('Get-DaikinStatus','Set-DaikinAirCon')
  FileList = @('.\docs\PS.Tools.Daikin.md','.\docs\en-US\Get-DaikinStatus.md','.\docs\en-US\PS.Tools.Daikin-help.xml','.\docs\en-US\Set-DaikinAirCon.md','.\include\ModuleHelperFunctions.ps1','.\private\Convert-DaikinResponse.ps1','.\private\Get-DaikinBasicInfo.ps1','.\private\Get-DaikinControlInfo.ps1','.\private\Get-DaikinModelInfo.ps1','.\private\Get-DaikinPollingConfiguration.ps1','.\private\Get-DaikinSensorInfo.ps1','.\private\Get-DaikinWeekStats.ps1','.\private\Get-DaikinYearStats.ps1','.\private\Resolve-DaikinHostname.ps1','.\private\Test-DaikinConnectivity.ps1','.\public\Get-DaikinStatus.ps1','.\public\Set-DaikinAirCon.ps1','.\settings\config.json','.\license.txt','.\PS.Tools.Daikin.psd1','.\PS.Tools.Daikin.psm1')
  PrivateData = @{
    ModuleName = 'PS.Tools.Daikin'
    DateCreated = '2020-10-03'
    LastBuildDate = '2020-11-30'
    ModuleType = ''
    PSData = @{
      Tags = @()
      ProjectUri = ''
      LicenseUri = ''
      ReleaseNotes = ''
      IsPrerelease = 'False'
      IconUri = ''
      PreRelease = ''
      RequireLicenseAcceptance = $True
      ExternalModuleDependencies = @()
    }
  }
  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()
  DscResourcesToExport = @()
  ModuleList = @()
  RequiredAssemblies = @()
  ScriptsToProcess = @()
  TypesToProcess = @()
  FormatsToProcess = @()
  NestedModules = @()
  HelpInfoURI = ''
  DefaultCommandPrefix = ''
  PowerShellVersion = '5.1'
  PowerShellHostName = ''
  PowerShellHostVersion = ''
  DotNetFrameworkVersion = ''
  CLRVersion = ''
  ProcessorArchitecture = ''
}



