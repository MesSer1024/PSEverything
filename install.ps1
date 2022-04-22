param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
    ,
    [switch] $Rebuild
)

$man = Import-PowerShellDataFile $PSScriptRoot/PSEverything/PSEverything.psd1

$name = 'PSEverything'
[string]$version = $man.ModuleVersion


$vspath = (Get-VSSetupInstance -All | Sort-Object InstallationVersion -Descending -top 1).InstallationPath

$msbuild = "$vspath\Msbuild\Current\Bin\MSBuild.exe"
[string] $sln = Resolve-Path "$PSScriptRoot\$Name.sln"

if ($msbuild -eq $Null) {
    throw "Cannot find msbuild.exe"
}

$msbuildArgs = @("/p:Configuration=$Configuration")
if ($Rebuild) {
    $msbuildArgs += '/target:rebuild'
}
else {
    $msbuildArgs += '/target:build'
}
$msbuildArgs += $sln
"$msbuildArgs"
dotnet build -c $Configuration  $msbuildArgs
dotnet test


$moduleSourceDir = "$PSScriptRoot/PSEverything/bin/$Configuration/netstandard2.0/"
$moduleDir = "~/documents/PowerShell/Modules/$name/$version/"

$newLine = [Environment]::NewLine

Set-StrictMode -Version Latest


$ofs = $newLine
[string]$about_content = Get-Content $PSScriptRoot/README.md | ForEach-Object {
    $_ -replace '```.*', ''
}

if (-not (Test-Path $moduleDir)) {
    $null = mkdir $moduleDir
}

Get-ChildItem $moduleSourceDir | Copy-Item -Destination $moduleDir -ErrorAction:Continue
Set-Content -Path $moduleDir/about_${name}.help.txt -value $about_content

$man = Test-ModuleManifest $moduleDir/PSEverything.psd1

$cert = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert
if ($cert) {
    Get-ChildItem $moduleDir/*.ps?1, $moduleDir/*.dll | Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll
}

Get-Item $ModuleDir
