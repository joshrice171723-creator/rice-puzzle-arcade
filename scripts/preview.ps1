param([ValidateSet('grid-foundry','merge-drift','color-cascade','nightfall-arena')][string]$App = 'grid-foundry')
$ErrorActionPreference = 'Stop'
$ports = @{ 'grid-foundry' = 8081; 'merge-drift' = 8082; 'color-cascade' = 8083; 'nightfall-arena' = 8084 }
$repoPath = Split-Path $PSScriptRoot -Parent
# Preview does not need the separately downloaded React Native debugger desktop app.
$env:EXPO_UNSTABLE_HEADLESS = '1'
$env:EXPO_OFFLINE = '1'
$env:EXPO_NO_CACHE_VARY = '1'
$env:CI = '1'
# Keep localhost reachable by the desktop browser's IPv4 loopback proxy.
$env:NODE_OPTIONS = (($env:NODE_OPTIONS + ' --dns-result-order=ipv4first').Trim())
Push-Location (Join-Path $repoPath "apps/$App")
try {
  & node ../../node_modules/expo/bin/cli start --web --localhost --max-workers 1 --port $ports[$App]
  if ($LASTEXITCODE -ne 0) { throw "Preview exited with code $LASTEXITCODE" }
} finally { Pop-Location }
