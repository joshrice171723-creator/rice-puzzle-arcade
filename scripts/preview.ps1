param([ValidateSet('grid-foundry','merge-drift','color-cascade')][string]$App = 'grid-foundry')
$ErrorActionPreference = 'Stop'
$ports = @{ 'grid-foundry' = 8081; 'merge-drift' = 8082; 'color-cascade' = 8083 }
$repoPath = Split-Path $PSScriptRoot -Parent
# Preview does not need the separately downloaded React Native debugger desktop app.
$env:EXPO_UNSTABLE_HEADLESS = '1'
$env:EXPO_OFFLINE = '1'
$env:EXPO_NO_CACHE_VARY = '1'
$env:CI = '1'
Push-Location (Join-Path $repoPath "apps/$App")
try {
  & node ../../node_modules/expo/bin/cli start --web --localhost --max-workers 1 --port $ports[$App]
  if ($LASTEXITCODE -ne 0) { throw "Preview exited with code $LASTEXITCODE" }
} finally { Pop-Location }
