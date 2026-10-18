[CmdletBinding()]
param(
    [ValidateSet('all', 'grid-foundry', 'merge-drift', 'color-cascade')]
    [string]$App = 'all'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repository = Split-Path -Parent $PSScriptRoot
$games = if ($App -eq 'all') { @('grid-foundry', 'merge-drift', 'color-cascade') } else { @($App) }

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}

foreach ($command in @('node', 'pnpm', 'java')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Missing $command. See docs/BUILD.md." }
}
if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) { throw 'Set ANDROID_HOME to an existing Android SDK. See docs/BUILD.md.' }
if (-not (Test-Path -LiteralPath (Join-Path $repository 'node_modules/expo/package.json'))) { throw 'Install dependencies with pnpm install --frozen-lockfile before building.' }

$environmentNames = @('EXPO_PUBLIC_BUILD_PROFILE', 'EXPO_PUBLIC_ADS_MODE', 'EAS_BUILD_PROFILE', 'CI')
$previousEnvironment = @{}
foreach ($name in $environmentNames) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:EXPO_PUBLIC_BUILD_PROFILE = 'internal'
    $env:EAS_BUILD_PROFILE = 'internal'
    $env:EXPO_PUBLIC_ADS_MODE = 'test'
    $env:CI = '1'
    foreach ($game in $games) {
        $appDirectory = Join-Path $repository "apps/$game"
        $artifactDirectory = Join-Path $repository "artifacts/android/$game"
        New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
        Push-Location $appDirectory
        try {
            Invoke-Checked 'pnpm' @('exec', 'expo', 'prebuild', '--platform', 'android', '--no-install')
            $properties = Get-Content -Raw -LiteralPath 'android/gradle.properties'
            if ($properties -notmatch '(?m)^android.targetSdkVersion=(3[6-9]|[4-9]\d)\s*$') { throw 'Generated Android target SDK must be at least API 36.' }
            $manifest = Get-Content -Raw -LiteralPath 'android/app/src/main/AndroidManifest.xml'
            if ($manifest -notmatch 'ca-app-pub-3940256099942544~3347511713') { throw 'Internal build requires the official Google Android test App ID.' }
            Push-Location android
            try {
                $wrapper = if ($env:OS -eq 'Windows_NT') { '.\gradlew.bat' } else { './gradlew' }
                if ($env:OS -ne 'Windows_NT') { Invoke-Checked 'chmod' @('+x', './gradlew') }
                & $wrapper ':app:assembleRelease' ':app:bundleRelease' '--no-daemon' '--stacktrace' '-PreactNativeArchitectures=arm64-v8a,x86_64' 2>&1 |
                    Tee-Object -FilePath (Join-Path $artifactDirectory 'gradle.log')
                if ($LASTEXITCODE -ne 0) { throw "Gradle failed with exit code $LASTEXITCODE; see artifacts/android/$game/gradle.log" }
            } finally { Pop-Location }
            $apk = Join-Path $artifactDirectory "$game-internal-test.apk"
            $aab = Join-Path $artifactDirectory "$game-internal-test.aab"
            Copy-Item -LiteralPath 'android/app/build/outputs/apk/release/app-release.apk' -Destination $apk
            Copy-Item -LiteralPath 'android/app/build/outputs/bundle/release/app-release.aab' -Destination $aab
            @($apk, $aab) | ForEach-Object {
                $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $_
                '{0}  {1}' -f $hash.Hash.ToLowerInvariant(), (Split-Path -Leaf $_)
            } | Set-Content -Encoding utf8 -LiteralPath (Join-Path $artifactDirectory 'SHA256SUMS.txt')
            @(
                'INTERNAL TEST ONLY. Official Google test ads; generated development signing key.'
                'The AAB is a native build verification artifact. It is not a Play publishing artifact.'
                'Supported ABIs: arm64-v8a and x86_64. Target SDK 36 or greater; compile SDK 37.'
            ) | Set-Content -Encoding utf8 -LiteralPath (Join-Path $artifactDirectory 'BUILD-NOTICE.txt')
            Write-Output "Built $apk and $aab"
        } finally { Pop-Location }
    }
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process') }
}
