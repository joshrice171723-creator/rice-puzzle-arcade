param([switch]$Launch)
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../artifacts/desktop/Game Studio-win32-x64'))
if (!(Test-Path -LiteralPath (Join-Path $source 'Game Studio.exe'))) { throw 'Build first: npm run package in studio/desktop.' }
$version = (Get-Content (Join-Path $PSScriptRoot 'package.json') -Raw | ConvertFrom-Json).version
$target = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA "Programs/GameStudio/$version"))
$running = Get-Process 'Game Studio' -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $target 'Game Studio.exe') }
if ($running) { throw 'Close Game Studio before updating this version.' }
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
$shell = New-Object -ComObject WScript.Shell
foreach ($folder in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
  $shortcut = $shell.CreateShortcut((Join-Path $folder 'Game Studio.lnk'))
  $shortcut.TargetPath = Join-Path $target 'Game Studio.exe'
  $shortcut.WorkingDirectory = $target
  $shortcut.Description = 'Live analytics for all studio games'
  $shortcut.Save()
}
Write-Output "Installed: $target"
if ($Launch) { Start-Process -FilePath (Join-Path $target 'Game Studio.exe') -WindowStyle Normal }
