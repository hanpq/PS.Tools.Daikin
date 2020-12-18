
#region Module Configuration

function Get-ModuleConfiguration {
    try {
        Get-Variable -Scope Global -Name ('ModuleConfiguration_{0}' -f ($MyInvocation.MyCommand.Module.Name)) -ValueOnly -ErrorAction Stop
    } catch {
        Write-Error -Message 'Failed to retrevie module configuration' -ErrorRecord $_
    }
}

function Initialize-ModuleConfiguration {
    # Define ModuleConfiguration class
    class ModuleConfiguration {
        [string]$ModuleName = ''
        [string]$ModuleRootPath = ''
        [string]$ModuleManifestPath = ''
        [hashtable]$ModuleFolders = @{}
        [hashtable]$ModuleFiles = @{}
        [hashtable]$ModuleFilePaths = @{}
        $ModuleManifest

        [void] CollectModuleFilePaths () {
            Get-ChildItem -Path $this.ModuleRootPath -Recurse -File | foreach-object {
                $this.ModuleFilePaths.($PSItem.Name) = $PSItem.FullName
            }
        }

        [void] ImportFiles () {
            foreach ($File in (Get-ChildItem -Path $this.ModuleFolders.Settings -File -Recurse)) {
                try {
                    $Content = $null
                    switch ($File.Extension) {
                        '.csv' { $Content = Import-Csv $File.FullName -Delimiter ';' -Encoding UTF8 -ErrorAction Stop }
                        '.psd1' { $Content = Import-PowerShellDataFile -Path $File.fullname -ErrorAction Stop }
                        '.json' { $Content = Get-Content -Path $File.FullName -ErrorAction Stop -raw | ConvertFrom-Json -ErrorAction Stop }
                        '.cred' { $Content = Import-Clixml -Path $File.FullName  -ErrorAction Stop }
                        default {
                            Write-Warning -Message 'Failed to import configuration file, unknown extension' -Target $File.Name
                            $Content = $null
                        }
                    }
                    if ($Content) {
                        $null = $this.ModuleFiles.Add($File.BaseName, $Content)
                    }
                } catch {
                    Write-Error -Message 'Failed to import configuration' -Targetobject $File.BaseName -ErrorRecord $_
                }
            }
        }

        ModuleConfiguration (
            $MyInvoc
        ) {
            # ModuleName
            $this.ModuleName = $MyInvoc.MyCommand.Module.Name

            # ModuleRootPath
            $this.ModuleRootPath = $MyInvoc.PSScriptRoot

            # ModuleFolders
            Get-ChildItem -Path $this.ModuleRootPath -Directory | ForEach-Object { $null = $this.ModuleFolders.Add($_.Name, $_.Fullname) }
            
            # ModuleManifestPath
            $this.ModuleManifestPath = (Join-Path -Path $this.ModuleRootPath -ChildPath ('{0}.psd1' -f $this.ModuleName))

            # ModuleManifest
            $this.ModuleManifest = Import-PowershellDataFile -Path $this.ModuleManifestPath

            # ModuleFiles
            $this.ImportFiles()

            # ModuleFilePaths
            $this.CollectModuleFilePaths()
        }
    }

    # Store module configuration
    try {
        $null = New-Variable -Scope Global -Name ('ModuleConfiguration_{0}' -f ($MyInvocation.MyCommand.Module.Name)) -Value ([ModuleConfiguration]::New($MyInvocation)) -Force -ErrorAction Stop
    } catch {
        Write-Error -Message 'Failed to store ModuleConfiguration' -ErrorRecord $_
    }
}

#endregion

#region Logging

# Class definition
class PSLogEntry {
    [string]$Message
    [string]$MessageForConsole
    [string]$Target
    [datetime]$TimeStamp
    [string]$Severity
    [string]$Source
    $LogSettings
    $ErrorRecord
    $ChangeObject
    

    [void]WriteToConsole() {
        switch ($this.Severity) {
            'SKIP' {
                Write-Host -Object ('SKIP: {0}' -f $this.MessageForConsole) -ForegroundColor Yellow
            }
            'SUCCESS' {
                Write-Host -Object ('SUCCESS: {0}' -f $this.MessageForConsole) -ForegroundColor Green
            }
            'INFO' {
                Write-Host -Object ('INFO: {0}' -f $this.MessageForConsole)
            }
            'TASK' {
                Write-host
                Write-host (' Task | ') -foregroundcolor Cyan -NoNewline
                Write-host $This.Message -ForegroundColor Magenta -NoNewline 
                Write-Host ' |' -ForegroundColor Cyan
            }
            'ERROR' {
                Write-Host -Object ('ERROR: {0}' -f $this.MessageForConsole) -ForegroundColor Red

                if ($this.ErrorRecord) {
                    if ($this.ErrorRecord.InvocationInfo) {
                        Write-Host  -Object ('          {0,-20}{1}' -f '+ ScriptName: ', $this.ErrorRecord.InvocationInfo.ScriptName) -ForegroundColor Red
                        Write-Host  -Object ('          {0,-20}{1}' -f '+ LineNbr: ', $this.ErrorRecord.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
                        Write-Host  -Object ('          {0,-16}{1}' -f '+ Code:', $this.ErrorRecord.InvocationInfo.Line.Replace("`r", "").Replace("`n", "").TrimStart(' ')) -ForegroundColor Red
                    }
                    Write-Host  -Object ('          {0,-20}{1}' -f '+ ExpMessage:', $this.ErrorRecord.Exception.Message) -ForegroundColor Red
                }
            }
            'CHANGE' {
                function Write-PSProperty {
                    param ($Value)
                    Write-Host '[' -ForegroundColor Magenta -NoNewline
                    Write-Host $Value -ForegroundColor Blue -NoNewline
                    Write-Host ']' -ForegroundColor Magenta -NoNewline
                }

                function Write-PSResult {
                    param($Result)
                    switch ($Result) {
                        'SUCCESS' {
                            Write-Host ' succeeded' -ForegroundColor Green -NoNewline
                        }
                        'FAILED' {
                            Write-Host ' failed' -ForegroundColor Red -NoNewline
                        }
                        'UNCHANGED' {
                            Write-Host ' was skipped, no change' -ForegroundColor Yellow -NoNewline
                        }
                    }
                }

                switch ($this.ChangeObject.Operation) {
                    'Add' {
                        Write-Host 'CHANGE:   Adding value ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Value
                        Write-Host ' to property ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Property
                        Write-Host ' for target ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Target
                        Write-PSResult -Result $this.ChangeObject.Result
                        Write-Host
                    }
                    'Remove' {
                        Write-Host 'CHANGE:   Removing value ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Value
                        Write-Host ' to property ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Property
                        Write-Host ' for target ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Target
                        Write-PSResult -Result $this.ChangeObject.Result
                        Write-Host
                    }
                    'replace' {
                        Write-Host 'CHANGE:   Replacing value ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.PreviousValue
                        Write-Host ' with new value ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Value
                        Write-Host ' in property ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Property
                        Write-Host ' for target ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Target
                        Write-PSResult -Result $this.ChangeObject.Result
                        Write-Host
                    }
                    'Clear' {
                        Write-Host 'CHANGE:   Clearing value ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.PreviousValue
                        Write-Host ' from property ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Property
                        Write-Host ' for target ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Target
                        Write-PSResult -Result $this.ChangeObject.Result
                        Write-Host
                    }
                    'Move' {
                        Write-Host 'CHANGE:   Moving object ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Target
                        Write-Host ' from ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.PreviousValue
                        Write-Host ' to ' -NoNewline
                        Write-PSProperty -Value $this.ChangeObject.Value
                        Write-PSResult -Result $this.ChangeObject.Result
                        Write-Host  
                    }
                }
            }
        }
    }
    
    [void]WriteToFile() {
        $ConvertFromCSVSplatting = @{
            Delimiter   = ';'
            Header      = 'Datetime', 'Source' , 'Type', 'Target', 'Message'
            InputObject = ('{0};{1};{4};{2};{3}' -f $this.TimeStamp.ToString('yyyy-MM-dd_HH:mm:ss:fff'), $this.Source , $this.Target, $this.Message, $this.Severity)
        }
        $ExportCSVSplatting = @{
            Path              = $this.LogSettings.GetLogFullName()
            Append            = $true
            NoTypeInformation = $true
            Encoding          = $this.LogSettings.Encoding
            Delimiter         = $this.LogSettings.LogDelimiter
        }
        ConvertFrom-Csv @ConvertFromCSVSplatting | Export-Csv @ExportCSVSplatting
        if ($this.ErrorRecord) {
            $this.WriteErrorRecordToFile()
        }
    }

    [void]WriteErrorRecordToFile() {
        $ExportCSVSplatting = @{
            Path              = $this.LogSettings.GetLogFullName()
            Append            = $true
            NoTypeInformation = $true
            Encoding          = $this.LogSettings.Encoding
            Delimiter         = $this.LogSettings.LogDelimiter
        } 
        $ConvertFromCSVSplatting = @{
            Delimiter   = ';'
            Header      = 'Datetime', 'Source' , 'Type', 'Target', 'Message'
            InputObject = ''
        }
        if ($this.ErrorRecord.InvocationInfo) {
            $ConvertFromCSVSplatting.InputObject = ('{0};{1};{4};{2};{3}' -f $this.TimeStamp.ToString('yyyy-MM-dd_HH:mm:ss:fff'), $this.Source , $this.Target, (' + ScriptName: {0}' -f $this.ErrorRecord.InvocationInfo.ScriptName) , $this.Severity)
            ConvertFrom-Csv @ConvertFromCSVSplatting | Export-Csv @ExportCSVSplatting
            $ConvertFromCSVSplatting.InputObject = ('{0};{1};{4};{2};{3}' -f $this.TimeStamp.ToString('yyyy-MM-dd_HH:mm:ss:fff'), $this.Source , $this.Target, (' + LineNbr:    {0}' -f $this.ErrorRecord.InvocationInfo.ScriptLineNumber)  , $this.Severity)
            ConvertFrom-Csv @ConvertFromCSVSplatting | Export-Csv @ExportCSVSplatting
            $ConvertFromCSVSplatting.InputObject = ('{0};{1};{4};{2};{3}' -f $this.TimeStamp.ToString('yyyy-MM-dd_HH:mm:ss:fff'), $this.Source , $this.Target, (' + Code:       {0}' -f $this.ErrorRecord.InvocationInfo.Line.Replace("`r", "").Replace("`n", ""))  , $this.Severity)
            ConvertFrom-Csv @ConvertFromCSVSplatting | Export-Csv @ExportCSVSplatting
        }    
        $ConvertFromCSVSplatting.InputObject = ('{0};{1};{4};{2};{3}' -f $this.TimeStamp.ToString('yyyy-MM-dd_HH:mm:ss:fff'), $this.Source , $this.Target, (' + ExpMessage: {0}' -f $this.ErrorRecord.Exception.Message)  , $this.Severity)
        ConvertFrom-Csv @ConvertFromCSVSplatting | Export-Csv @ExportCSVSplatting
    }

    [string]FindSource() {
        return (get-pscallstack).Where( { $_.Command -ne '' -and $_.Command -notlike '*<ScriptBlock>*' }) | select-object -skip 1 | select-object -first 1 | select-object -expandproperty location        
    }

    [void]UpdateMessage() {
        $Separator = [string]''
        for ($i = 0; $i -lt (9 - ($this.Severity.Length + 2))  ; $i++) {
            $Separator += ' '
        }
        if ($this.Target -eq 'N/A') {
            $this.MessageForConsole = ('{0}{1}' -f $Separator, $this.Message)
        } else {
            $this.MessageForConsole = ('{0}{1} | {2}' -f $Separator, $this.Target, $this.Message)
        }
    }

    PSLogEntry (
        [string]$Target,
        [string]$Severity,
        [System.Management.Automation.EngineIntrinsics]$ExecCon,
        $ChangeObject
    ) {
        $this.LogSettings = (Get-PSLogSettings)
        $this.Target = $Target
        $this.Severity = $Severity
        $this.ChangeObject = $ChangeObject
    }

    PSLogEntry (
        [string]$Message,
        [string]$Severity,
        [System.Management.Automation.EngineIntrinsics]$ExecCon
    ) {
        $this.LogSettings = Get-PSLogSettings
        $this.Message = $Message
        $this.Target = $this.LogSettings.DefaultTargetValue
        $this.TimeStamp = (Get-Date)
        $this.Severity = $Severity
        $this.Source = $this.FindSource()
        $this.UpdateMessage()
    }

    PSLogEntry (
        [string]$Message,
        [string]$Severity,
        [string]$Target,
        [System.Management.Automation.EngineIntrinsics]$ExecCon
    ) {
        $this.LogSettings = Get-PSLogSettings
        $this.Message = $Message
        $this.Target = $Target
        $this.TimeStamp = (Get-Date)
        $this.Severity = $Severity
        $this.Source = $this.FindSource()
        $this.UpdateMessage()
    }
    PSLogEntry (
        [string]$Message,
        [string]$Severity,
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [System.Management.Automation.EngineIntrinsics]$ExecCon
    ) {
        $this.LogSettings = Get-PSLogSettings
        $this.ErrorRecord = $ErrorRecord
        $this.Message = $Message
        $this.Target = $this.LogSettings.DefaultTargetValue
        $this.TimeStamp = (Get-Date)
        $this.Severity = $Severity
        $this.Source = $this.FindSource()
        $this.UpdateMessage()
    }

    PSLogEntry (
        [string]$Message,
        [string]$Severity,
        [string]$Target,
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [System.Management.Automation.EngineIntrinsics]$ExecCon
    ) {
        $this.LogSettings = Get-PSLogSettings
        $this.ErrorRecord = $ErrorRecord
        $this.Message = $Message
        $this.Target = $Target
        $this.TimeStamp = (Get-Date)
        $this.Severity = $Severity
        $this.Source = $this.FindSource()
        $this.UpdateMessage()
    }
}

class PSLogSettings {
    [string]$DefaultTargetValue = 'N/A'
    [string]$LogFileTurnOver = 'Daily'
    [string]$LogDirectory
    [string]$LogNamePrefix = ''
    [string]$LogName = '{0}.log' -f (Get-Date).ToString('yyyy-MM-dd')
    [string]$ChangeLogName = '{0}_ChangeLog.log' -f (Get-Date).ToString('yyyy-MM-dd')
    [string]$LogDelimiter = ';'
    [string]$Encoding = 'UTF8'


    [string]GetLogName() {
        return $this.LogNamePrefix + $this.LogName
    }

    [string]GetChangeLogName() {
        return $this.LogNamePrefix + $this.ChangeLogName
    }

    [string]GetLogFullName() {
        return (Join-Path -Path $this.LogDirectory -ChildPath $this.GetLogName())
    }

    [string]GetChangeLogFullName() {
        return (Join-Path -Path $this.LogDirectory -ChildPath $this.GetChangeLogName())
    }

    PSLogSettings(
        $LogDirectory
    ) {
        $this.LogDirectory = $LogDirectory
    }
}

function Get-PSLogSettings {
    [Cmdletbinding()]
    param()

    process {
        Get-Variable -Name (Get-PSLogSettingsVarName) -ValueOnly
    }
}

function Get-PSLogSettingsVarName {
    return ('LogSettings')
}

function Test-PSLogSettings {
    if (Get-PSLogSettings -ErrorAction SilentlyContinue) {
        return $true
    } else {
        return $false
    }
}

function Initialize-PSLogSettings {
    if (-not (Test-PSLogSettings)) {
        if (Test-PSLogDirectoryPath) {
            $null = New-Variable -scope script -Name (Get-PSLogSettingsVarName) -Value ([PSLogSettings]::New((Resolve-Path -Path "$PSScriptRoot\..\logs"))) -PassThru -Force
        } else {
            $null = New-Variable -scope script -Name (Get-PSLogSettingsVarName) -Value ([PSLogSettings]::New((Resolve-Path -Path "$PSScriptRoot"))) -PassThru -Force
        }
    }
}

function Test-PSLogDirectoryPath {
    if (Test-Path -Path "$PSScriptRoot\..\logs") {
        return $true
    } else {
        return $false
    }
}

function Set-PSLogDirectory {
    param(
        [Parameter(Mandatory)]
        [string]
        $LogDirectory
    )
    if (Test-PSLogSettings) {
        $LogSettings = Get-PSLogSettings
        $LogSettings.LogDirectory = $LogDirectory
        Set-Variable -Name (Get-PSLogSettingsVarName) -Value $LogSettings
    } else {
        Initialize-PSLogSettings
        Set-PSLogDirectory -LogDirectory $LogDirectory
    }
}

function Write-Warning {
    <#
        .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Warning
        .ForwardHelpCategory Cmdlet
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113430', RemotingCapability = 'None', DefaultParameterSetName = 'Plain')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'The sole purpose of this function is do override the default behaviour')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message},

        [Parameter(Position = 1)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 2)]
        [switch]
        $File

    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Warning', [System.Management.Automation.CommandTypes]::Cmdlet)
            
            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState 

            # Create PSLogEntry object
            if ($Target) {
                $PSLogEntry = [PSLogEntry]::New($Message, 'WARNING', $Target, $ExecutionContext)
            } else {
                $PSLogEntry = [PSLogEntry]::New($Message, 'WARNING', $ExecutionContext)
            }

            # Write to file if selected
            if ($File) {
                $PSLogEntry.WriteToFile()
            }

            # Cleanup PSBoundParameters
            $PSBoundParameters.Remove('Message') | Out-Null
            $PSBoundParameters.Add('Message', $PSLogEntry.MessageForConsole) | Out-Null
            $PSBoundParameters.Remove('Target') | Out-Null
            $PSBoundParameters.Remove('File') | out-null

            # Invoke stock cmdlet
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

function Write-Error {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'The sole purpose of this file')]
    [CmdletBinding(DefaultParameterSetName = 'NoException', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2097039', RemotingCapability = 'None')]
    param(
        [Parameter(ParameterSetName = 'WithException', Mandatory = $true)]
        [System.Exception]
        ${Exception},

        [Parameter(ParameterSetName = 'WithException')]
        [Parameter(ParameterSetName = 'NoException', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'ErrorRecord')]
        [Alias('Msg')]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        ${Message},

        [Parameter(ParameterSetName = 'ErrorRecord', Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        ${ErrorRecord},

        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [System.Management.Automation.ErrorCategory]
        ${Category},

        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [string]
        ${ErrorId},

        [Parameter(ParameterSetName = 'NoException')]
        [Parameter(ParameterSetName = 'WithException')]
        [Parameter(ParameterSetName = 'ErrorRecord')]
        [System.Object]
        ${TargetObject},

        [string]
        ${RecommendedAction},

        [Alias('Activity')]
        [string]
        ${CategoryActivity},

        [Alias('Reason')]
        [string]
        ${CategoryReason},

        [Alias('TargetName')]
        [string]
        ${CategoryTargetName},

        [Alias('TargetType')]
        [string]
        ${CategoryTargetType},
    
        [switch]
        $File
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState 

            #$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Error', [System.Management.Automation.CommandTypes]::Cmdlet)

            if ($Exception) {
                $ErrorRecord = New-Object Management.Automation.ErrorRecord $Exception, 'CustomErrorRecord', 'NotSpecified' , 'N/A'
            }

            # Create PSLogEntry object
            if ($TargetObject -and $TargetObject -is [string]) {
                if ($ErrorRecord) {
                    $PSLogEntry = [PSLogEntry]::New($Message, 'ERROR', $TargetObject, $ErrorRecord, $ExecutionContext)
                } else {
                    $PSLogEntry = [PSLogEntry]::New($Message, 'ERROR', $TargetObject, $ExecutionContext)
                }
            } else {
                if ($ErrorRecord) {
                    $PSLogEntry = [PSLogEntry]::New($Message, 'ERROR', $ErrorRecord, $ExecutionContext)
                } else {
                    $PSLogEntry = [PSLogEntry]::New($Message, 'ERROR', $ExecutionContext)
                }
            }

            if ($File) {
                $PSLogEntry.WriteToFile()
            }

            if ($Message) {
                $PSLogEntry.WriteToConsole()
            } elseif ($ErrorRecord) {
                $ErrorRecord
            }

            if (-not $Message -and -not $ErrorRecord) {
                $scriptCmd = { & $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            }

        } catch {
            throw
        }
    }

    process {
        try {
            #$steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            #$steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

.ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Error
.ForwardHelpCategory Cmdlet

#>
}

function Write-Success {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $Message,

        [Parameter(Position = 1)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 2)]
        [switch]
        $File

    )

    process {

        # Create PSLogEntry object
        if ($Target) {
            $PSLogEntry = [PSLogEntry]::New($Message, 'SUCCESS', $Target, $ExecutionContext)
        } else {
            $PSLogEntry = [PSLogEntry]::New($Message, 'SUCCESS', $ExecutionContext)
        }

        # Write to file if selected
        if ($File) {
            $PSLogEntry.WriteToFile()
        }

        # Write to console
        $PSLogEntry.WriteToConsole()

    }
}

function Write-Skip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $Message,

        [Parameter(Position = 1)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 2)]
        [switch]
        $File

    )

    process {

        # Create PSLogEntry object
        if ($Target) {
            $PSLogEntry = [PSLogEntry]::New($Message, 'SKIP', $Target, $ExecutionContext)
        } else {
            $PSLogEntry = [PSLogEntry]::New($Message, 'SKIP', $ExecutionContext)
        }

        # Write to file if selected
        if ($File) {
            $PSLogEntry.WriteToFile()
        }

        # Write to console
        $PSLogEntry.WriteToConsole()
    }
}

function Write-Information {
    <#

      .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Information
      .ForwardHelpCategory Cmdlet

  #>

    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=525909', RemotingCapability = 'None')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'The sole purpose of this function is do override the default behaviour')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('Msg')]
        [Alias('MessageData')]
        [System.Object]
        ${Message},

        [Parameter(Position = 1)]
        [string[]]
        ${Tags},

        [Parameter(Position = 2)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 3)]
        [switch]
        $File
    
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState 

            # Create PSLogEntry object
            if ($Target) {
                $PSLogEntry = [PSLogEntry]::New($Message, 'INFO', $Target, $ExecutionContext)
            } else {
                $PSLogEntry = [PSLogEntry]::New($Message, 'INFO', $ExecutionContext)
            }

            # Write to file if selected
            if ($File) {
                $PSLogEntry.WriteToFile()
            }

            $PSLogEntry.WriteToConsole()

        } catch {
            throw
        }
    }
}

function Write-Verbose {
    <#

      .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Verbose
      .ForwardHelpCategory Cmdlet

  #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113429', RemotingCapability = 'None')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'The sole purpose of this function is do override the default behaviour')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [Alias('Msg')]
        [string]
        ${Message},

        [Parameter(Position = 1)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 2)]
        [switch]
        $File
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)

            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState 

            # Create PSLogEntry object
            if ($Target) {
                $PSLogEntry = [PSLogEntry]::New($Message, 'VERBOSE', $Target, $ExecutionContext)
            } else {
                $PSLogEntry = [PSLogEntry]::New($Message, 'VERBOSE', $ExecutionContext)
            }

            # Write to file if selected
            if ($File) {
                $PSLogEntry.WriteToFile()
            }

            # Cleanup PSBoundParameters
            $PSBoundParameters.Remove('Message') | Out-Null
            $PSBoundParameters.Add('Message', $PSLogEntry.MessageForConsole) | Out-Null
            $PSBoundParameters.Remove('Target') | Out-Null
            $PSBoundParameters.Remove('File') | out-null

            # Invoke stock cmdlet
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

function Write-Debug {
    <#

      .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Debug
      .ForwardHelpCategory Cmdlet

  #>

    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113424', RemotingCapability = 'None')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'The sole purpose of this function is do override the default behaviour')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [Alias('Msg')]
        [string]
        ${Message},

        [Parameter(Position = 1)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 2)]
        [switch]
        $File
    )
    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)

            Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState 

            # Create PSLogEntry object
            if ($Target) {
                $PSLogEntry = [PSLogEntry]::New($Message, 'DEBUG', $Target, $ExecutionContext)
            } else {
                $PSLogEntry = [PSLogEntry]::New($Message, 'DEBUG', $ExecutionContext)
            }

            # Write to file if selected
            if ($File) {
                $PSLogEntry.WriteToFile()
            }
            # Cleanup PSBoundParameters
            $PSBoundParameters.Remove('Message') | Out-Null
            $PSBoundParameters.Add('Message', $PSLogEntry.MessageForConsole) | Out-Null
            $PSBoundParameters.Remove('Target') | Out-Null
            $PSBoundParameters.Remove('File') | out-null

            # Invoke stock cmdlet
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

function Write-Change {
    param (
        [Parameter(Position = 0, Mandatory)]
        [Alias('TargetObject')]
        [string]
        $Target,

        [Parameter(Position = 1, Mandatory, ParameterSetName = 'Add')]
        [switch]
        $Add,
        [Parameter(Position = 1, Mandatory, ParameterSetName = 'Remove')]
        [switch]
        $Remove,
        [Parameter(Position = 1, Mandatory, ParameterSetName = 'Replace')]
        [switch]
        $Replace,
        [Parameter(Position = 1, Mandatory, ParameterSetName = 'Clear')]
        [switch]
        $Clear,
        [Parameter(Position = 1, Mandatory, ParameterSetName = 'Move')]
        [switch]
        $Move,

        [Parameter(Mandatory, ParameterSetName = 'Add')]
        [Parameter(Mandatory, ParameterSetName = 'Remove')]
        [Parameter(Mandatory, ParameterSetName = 'Replace')]
        [Parameter(Mandatory, ParameterSetName = 'Move')]
        [string]
        $Value,

        [Parameter(Mandatory, ParameterSetName = 'Replace')]
        [Parameter(Mandatory, ParameterSetName = 'Clear')]
        [Parameter(Mandatory, ParameterSetName = 'Move')]
        [string]
        $PreviousValue,

        [string]
        $Property = '',

        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Failed', 'Unchanged')]
        [string]
        $Result,

        [switch]
        $WriteToConsole
    )

    $LogSettings = (Get-PSLogSettings)

    $Object = [pscustomobject]@{
        TimeStamp     = (Get-Date).ToString('yyyy-MM-dd_HH:mm:ss:fff')
        Target        = $Target 
        Operation     = $PSCmdlet.ParameterSetName
        Result        = $Result
        Property      = $Property
        PreviousValue = $PreviousValue
        Value         = $Value
    }

    $Object | Export-CSV -Path $LogSettings.GetChangeLogFullName() -Delimiter $LogSettings.LogDelimiter -NoTypeInformation -Encoding $LogSettings.Encoding -Append
    
    if ($WriteToConsole) {
        $PSLogEntry = [PSLogEntry]::New($Message, 'CHANGE', $ExecutionContext, $Object)
        $PSLogEntry.WriteToConsole()
    }
}

function Write-PSProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Standard')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Completed')]
        [string]
        $Activity,

        [Parameter(Position = 1, ParameterSetName = 'Standard')]
        [Parameter(Position = 1, ParameterSetName = 'Completed')]     
        [ValidateRange(0, 2147483647)]
        [int]
        $Id,        
        
        [Parameter(Position = 2, ParameterSetName = 'Standard')]
        [string]
        $Target,
        
        [Parameter(Position = 3, ParameterSetName = 'Standard')]
        [Parameter(Position = 3, ParameterSetName = 'Completed')] 
        [ValidateRange(-1, 2147483647)]
        [int]
        $ParentId,

        [Parameter(Position = 4, ParameterSetname = 'Completed')]
        [switch]
        $Completed,

        [Parameter(Mandatory = $true, Position = 5, ParameterSetName = 'Standard')]
        [long]
        $Counter,

        [Parameter(Mandatory = $true, Position = 6, ParameterSetName = 'Standard')]
        [long]
        $Total,

        [Parameter(Position = 7, ParameterSetName = 'Standard')]
        [datetime]
        $StartTime,

        [Parameter(Position = 8, ParameterSetName = 'Standard')]
        [switch]
        $DisableDynamicUpdateFrquency,

        [Parameter(Position = 9, ParameterSetName = 'Standard')]
        [switch]
        $NoTimeStats
    )
    
    # Define current timestamp
    $TimeStamp = (Get-Date)

    # Define a dynamic variable name for the global starttime variable
    $StartTimeVariableName = ('ProgressStartTime_{0}' -f $Activity.Replace(' ', ''))

    # Manage global start time variable
    if ($PSBoundParameters.ContainsKey('Completed') -and (Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction SilentlyContinue)) {
        # Remove the global starttime variable if the Completed switch parameter is users
        try {
            Remove-Variable -Name $StartTimeVariableName -ErrorAction Stop -Scope Global
        } catch {
            throw $_
        }
    } elseif (-not (Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction SilentlyContinue)) {
        # Global variable do not exist, create global variable
        if ($null -eq $StartTime) {
            # No start time defined with parameter, use current timestamp as starttime
            Set-Variable -Name $StartTimeVariableName -Value $TimeStamp -Scope Global
            $StartTime = $TimeStamp
        } else {
            # Start time defined with parameter, use that value as starttime
            Set-Variable -Name $StartTimeVariableName -Value $StartTime -Scope Global
        }
    } else {
        # Global start time variable is defined, collect and use it
        $StartTime = Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction Stop -ValueOnly
    }
    
    # Define frequency threshold
    $Frequency = [Math]::Ceiling($Total / 100)
    switch ($PSCmdlet.ParameterSetName) {
        'Standard' {
            if (($DisableDynamicUpdateFrquency) -or ($Counter % $Frequency -eq 0) -or ($Counter -eq 1) -or ($Counter -eq $Total)) {
                
                # Calculations for both timestats and without
                $Percent = [Math]::Round(($Counter / $Total * 100), 0)
                $CountProgress = ('{0}/{1}' -f $Counter, $Total)
                if ($Percent -gt 100) { $Percent = 100 }
                $WriteProgressSplat = @{
                    Activity = $Activity
                    PercentComplete = $Percent
                    CurrentOperation = $Target
                }
                if ($Id) { $WriteProgressSplat.Id = $Id }
                if ($ParentId) { $WriteProgressSplat.ParentId = $ParentId }

                # Calculations for either timestats and without
                if ($NoTimeStats) {
                    $WriteProgressSplat.Status = ('{0} - {1}%' -f $CountProgress, $Percent)
                } else {
                    $TotalSeconds = ($TimeStamp - $StartTime).TotalSeconds
                    $SecondsPerItem = if ($Counter -eq 0) { 0 } else { ($TotalSeconds / $Counter) }
                    $ItemsPerSecond = ([Math]::Round(($Counter / $TotalSeconds), 2))
                    $SecondsRemaing = ($Total - $Counter) * $SecondsPerItem
                    $ETA = $(($Timestamp).AddSeconds($SecondsRemaing).ToShortTimeString())
                    $WriteProgressSplat.Status = ('{0} - {1}% - ETA: {2} - IpS {3}' -f $CountProgress, $Percent, $ETA, $ItemsPerSecond)
                    $WriteProgressSplat.SecondsRemaining = $SecondsRemaing
                }

                # Call writeprogress
                Write-Progress @WriteProgressSplat
            }
        }
        'Completed' {
            Write-Progress -Activity $Activity -Id $Id -Completed 
        }
    }
}

function Write-Task {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Message,

        [Parameter(Position = 1)]
        [switch]
        $File
    )

    # Create PSLogEntry object
    $PSLogEntry = [PSLogEntry]::New($Message, 'TASK', $ExecutionContext)

    # Write to file if selected
    if ($File) {
        $PSLogEntry.WriteToFile()
    }

    # Write to console
    $PSLogEntry.WriteToConsole()

}

function Write-CustomLogMessage {
    param(
        [Parameter(Mandatory)]
        [string]
        $Header,

        [System.ConsoleColor]
        $HeaderColor = [consolecolor]::Green,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Message,

        [System.ConsoleColor]
        $MessageColor = [consolecolor]::Gray,

        [char]
        $SeparatorChar = '|',

        [System.ConsoleColor]
        $SeparatorColor = [consolecolor]::Cyan
    )

    Write-Host ('{0}' -f $Header) -NoNewline -ForegroundColor $HeaderColor
    Write-host (' {0} ' -f $SeparatorChar) -NoNewline -ForegroundColor $SeparatorColor
    Write-Host ('{0}' -f $Message) -ForegroundColor $MessageColor

}

function Use-CallerPreference {
    <#
    .SYNOPSIS
    Sets the PowerShell preference variables in a module's function based on the callers preferences.
 
    .DESCRIPTION
    Script module functions do not automatically inherit their caller's variables, including preferences set by common parameters. This means if you call a script with switches like `-Verbose` or `-WhatIf`, those that parameter don't get passed into any function that belongs to a module.
 
    When used in a module function, `Use-CallerPreference` will grab the value of these common parameters used by the function's caller:
 
     * ErrorAction
     * Debug
     * Confirm
     * InformationAction
     * Verbose
     * WarningAction
     * WhatIf
     
    This function should be used in a module's function to grab the caller's preference variables so the caller doesn't have to explicitly pass common parameters to the module function.
 
    This function is adapted from the [`Get-CallerPreference` function written by David Wyatt](https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d).
 
    There is currently a [bug in PowerShell](https://connect.microsoft.com/PowerShell/Feedback/Details/763621) that causes an error when `ErrorAction` is implicitly set to `Ignore`. If you use this function, you'll need to add explicit `-ErrorAction $ErrorActionPreference` to every function/cmdlet call in your function. Please vote up this issue so it can get fixed.
 
    .LINK
    about_Preference_Variables
 
    .LINK
    about_CommonParameters
 
    .LINK
    https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d
 
    .LINK
    http://powershell.org/wp/2014/01/13/getting-your-script-module-functions-to-inherit-preference-variables-from-the-caller/
 
    .EXAMPLE
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
 
    Demonstrates how to set the caller's common parameter preference variables in a module function.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        #[Management.Automation.PSScriptCmdlet]
        # The module function's `$PSCmdlet` object. Requires the function be decorated with the `[CmdletBinding()]` attribute.
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [Management.Automation.SessionState]
        # The module function's `$ExecutionContext.SessionState` object. Requires the function be decorated with the `[CmdletBinding()]` attribute.
        #
        # Used to set variables in its callers' scope, even if that caller is in a different script module.
        $SessionState
    )

    Set-StrictMode -Version 'Latest'

    # List of preference variables taken from the about_Preference_Variables and their common parameter name (taken from about_CommonParameters).
    $commonPreferences = @{
        'ErrorActionPreference' = 'ErrorAction';
        'DebugPreference'       = 'Debug';
        'ConfirmPreference'     = 'Confirm';
        'InformationPreference' = 'InformationAction';
        'VerbosePreference'     = 'Verbose';
        'WarningPreference'     = 'WarningAction';
        'WhatIfPreference'      = 'WhatIf';
    }

    foreach ( $prefName in $commonPreferences.Keys ) {
        $parameterName = $commonPreferences[$prefName]

        # Don't do anything if the parameter was passed in.
        if ( $Cmdlet.MyInvocation.BoundParameters.ContainsKey($parameterName) ) {
            continue
        }

        $variable = $Cmdlet.SessionState.PSVariable.Get($prefName)
        # Don't do anything if caller didn't use a common parameter.
        if ( -not $variable ) {
            continue
        }

        if ( $SessionState -eq $ExecutionContext.SessionState ) {
            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
        } else {
            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
        }
    }

}

function Write-CheckListItem {
    param (
        $InfoChar = 'O',
        $InfoColor = 'White',
        $PositiveChar = '+',
        $PositiveColor = 'Green',
        $IntermediateChar = '/',
        $IntermediateColor = 'Yellow',
        $NegativeChar = '-',
        $NegativeColor = 'Red',
        [ValidateSet('Positive', 'Intermediate', 'Negative', 'Info')]
        $Severity = 'Info',
        $Message = '',
        $Milliseconds
    )

    switch ($Severity) {
        'Positive' {
            $SelectedColor = $PositiveColor
            $SelectedChar = $PositiveChar
        }
        'Intermediate' {
            $SelectedColor = $IntermediateColor
            $SelectedChar = $IntermediateChar
        }
        'Negative' {
            $SelectedColor = $NegativeColor
            $SelectedChar = $NegativeChar
        }
        'Info' {
            $SelectedColor = $InfoColor
            $SelectedChar = $InfoChar
        }
    }
    if ($Milliseconds) {
        Write-Host ('      [{0}] {1}  ' -f $SelectedChar, $Message) -ForegroundColor $SelectedColor -NoNewline; Write-Host (' {0}ms' -f ([Math]::Round($Milliseconds))) -ForegroundColor DarkGray
    } else {
        Write-Host ('      [{0}] {1}  ' -f $SelectedChar, $Message) -ForegroundColor $SelectedColor
    }
}
#endregion

#region Assert Functions 
filter Assert-FolderExists {
    $exists = Test-Path -Path $_ -PathType Container
    if (!$exists) { 
        Write-Warning "$_ did not exist. Folder created."
        $null = New-Item -Path $_ -ItemType Directory 
    }
}

filter Assert-FunctionRequirements {
    param(
        [string[]]
        $InstalledModules,

        [ValidateSet('Core','Desktop')]
        [string]
        $PowershellEdition,

        [ValidateSet('5.0','5.1','6.0','7.0')]
        [string]
        $PowershellVersionOrHigher,

        [string[]]
        $CmdletWhiteList,

        [switch]
        $Elevated,

        [switch]
        $NonElevated
    )

    $Result = $true

    foreach ($Key in $PSBoundParameters.Keys) {
        switch ($Key) {
            'InstalledModules' {
                foreach ($Module in $InstalledModules) {
                    if (-not ((Get-ChildItem -Path ((Get-ModuleConfiguration).ModuleFolders.Include) -Filter $Module) -or (Get-Module $Module -ListAvailable))) {
                        $Result = $false
                        Write-Error -Message ('Module availability failed for module [{0}]' -f $Module)
                    }
                }
            }
            'PowershellEdition' {
                if ($PSVersionTable.PSEdition -ne $PowershellEdition) {
                    $Result = $false
                    Write-Error -Message ('This cmdlet require PSEdition [{0}]' -f $PowershellEdition)
                }
            }
            'PowershellVersionOrHigher' {
                if ($PSVersionTable.PSVersion -lt ([system.version]$PowershellVersionOrHigher)) {
                    $Result = $false
                    Write-Error -Message ('This cmdlet require PSVersion [{0}] or higher' -f $PowershellVersionOrHigher)
                }
            }
            'Elevated' {
                if (-not (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
                    $Result = $false
                    Write-Error -Message ('This cmdlet requires an elevated host')
                }                
            }
            'NonElevated' {
                if ((([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
                    $Result = $false
                    Write-Error -Message ('This cmdlet requires an elevated host')
                }                
            }
        }
    }
    return $Result
}
#endregion

#region Other helper functions
filter Invoke-GarbageCollect {
    [system.gc]::Collect()
}
#endregion
