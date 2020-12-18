[Setup]
AppId={{ 5588fcbe-895e-4578-b1c3-9948bc62c746 }
AppName=PS.Tools.Daikin
AppVersion=1.0.1
AppPublisher=Crayon AD
AppPublisherURL=www.crayon.com
AppSupportURL=www.crayon.com
AppUpdatesURL=www.crayon.com
DefaultDirName={userdocs}\WindowsPowerShell\Modules\PS.Tools.Daikin
DisableDirPage=yes
DefaultGroupName=PS.Tools.Daikin
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=C:\Users\hanpalmq\Onedrive\DEV\PowerShell\PSSolutionModules\PS.Tools.Daikin\Builds
OutputBaseFilename=PS.Tools.Daikin.1.0.1.Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
Uninstallable=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "C:\Users\hanpalmq\Onedrive\DEV\PowerShell\PSSolutionModules\PS.Tools.Daikin\Export\PS.Tools.Daikin\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

[Icons]
Name: "{userdesktop}\PS.Tools.Daikin"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-executionpolicy bypass -noexit -noprofile -command ""Import-Module PS.Tools.Daikin;"""; IconFilename: "{app}\1.0.1\Data\CrayonIcon.ico"

[Run]
Filename: "{app}\1.0.1\docs\PS.Tools.Daikin Usage Instructions.docx"; Parameters: ; Description: "Open user guide (.docx, requires Word)"; Flags: postinstall nowait shellexec 
Filename: "Powershell.exe"; Parameters: "-executionpolicy bypass -noexit -noprofile -command ""Import-Module PS.Tools.Daikin;"""; Description: "Run PS.Tools.Daikin"; Flags: postinstall nowait
