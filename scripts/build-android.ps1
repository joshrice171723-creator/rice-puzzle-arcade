[CmdletBinding()]
param(
    [ValidateSet('all', 'grid-foundry', 'merge-drift', 'color-cascade', 'nightfall-arena')]
    [string]$App = 'all',
    [ValidateSet('arm64-v8a', 'x86_64', 'arm64-v8a,x86_64')]
    [string]$Architectures = 'arm64-v8a,x86_64',
    [switch]$RegenerateNative
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

if (-not (Test-Path -LiteralPath (Join-Path $repository 'node_modules/expo/package.json'))) { throw 'Install dependencies with pnpm install --frozen-lockfile before building.' }

$environmentNames = @('EXPO_PUBLIC_BUILD_PROFILE', 'EXPO_PUBLIC_ADS_MODE', 'EAS_BUILD_PROFILE', 'CI', 'JAVA_HOME', 'ANDROID_HOME', 'PATH')
$previousEnvironment = @{}
foreach ($name in $environmentNames) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$mappedDrive = $null
$buildRoot = $repository
try {
    if ($env:OS -eq 'Windows_NT') {
        $studioJava = Join-Path $env:ProgramFiles 'Android/Android Studio/jbr'
        if (-not $env:JAVA_HOME -and (Test-Path (Join-Path $studioJava 'bin/java.exe'))) { $env:JAVA_HOME = $studioJava }
        $localSdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
        if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT -and (Test-Path $localSdk)) { $env:ANDROID_HOME = $localSdk }
        foreach ($letter in @('R', 'Z', 'Y', 'X', 'W', 'V', 'U', 'T', 'S')) {
            if (-not (Get-PSDrive -Name $letter -ErrorAction SilentlyContinue)) {
                Invoke-Checked 'subst.exe' @("${letter}:", $repository)
                $mappedDrive = "${letter}:"
                $buildRoot = "${letter}:/"
                break
            }
        }
        if (-not $mappedDrive) { throw 'A free drive letter is needed for the Windows native build path.' }
    }
    if ($env:JAVA_HOME) { $env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH }
    foreach ($command in @('node', 'java')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Missing $command. See docs/BUILD.md." }
    }
    if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) { throw 'Set ANDROID_HOME to an existing Android SDK. See docs/BUILD.md.' }
    $env:EXPO_PUBLIC_BUILD_PROFILE = 'internal'
    $env:EAS_BUILD_PROFILE = 'internal'
    $env:EXPO_PUBLIC_ADS_MODE = 'test'
    $env:CI = '1'
    foreach ($game in $games) {
        $appDirectory = Join-Path $buildRoot "apps/$game"
        $artifactDirectory = Join-Path $repository "artifacts/android/$game"
        New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
        Push-Location $appDirectory
        try {
            if ($RegenerateNative -or -not (Test-Path -LiteralPath 'android/app/build.gradle')) {
                Push-Location (Join-Path $repository "apps/$game")
                try { Invoke-Checked 'node' @('../../node_modules/expo/bin/cli', 'prebuild', '--platform', 'android', '--no-install') }
                finally { Pop-Location }
            }
            $properties = Get-Content -Raw -LiteralPath 'android/gradle.properties'
            if ($properties -notmatch '(?m)^android.targetSdkVersion=(3[6-9]|[4-9]\d)\s*$') { throw 'Generated Android target SDK must be at least API 36.' }
            $manifest = Get-Content -Raw -LiteralPath 'android/app/src/main/AndroidManifest.xml'
            if ($manifest -notmatch 'ca-app-pub-3940256099942544~3347511713') { throw 'Internal build requires the official Google Android test App ID.' }
            Push-Location android
            try {
                $wrapper = if ($env:OS -eq 'Windows_NT') { '.\gradlew.bat' } else { './gradlew' }
                if ($env:OS -ne 'Windows_NT') { Invoke-Checked 'chmod' @('+x', './gradlew') }
                $gradleArguments = @(':app:assembleRelease', ':app:bundleRelease', '--no-daemon', '--max-workers=2', '--stacktrace', '-Pandroid.enableMinifyInReleaseBuilds=false', '-Pandroid.enableShrinkResourcesInReleaseBuilds=false', "-PreactNativeArchitectures=$Architectures")
                if ($env:OS -eq 'Windows_NT') { $gradleArguments += @('--init-script', (Join-Path $repository 'scripts/windows-cmake.gradle'), '-Pkotlin.incremental=false', "-ParcadePhysicalRoot=$repository") }
                # Windows PowerShell wraps even harmless javac stderr notes as errors.
                # Preserve the log and use Gradle's exit code to determine success.
                $previousErrorAction = $ErrorActionPreference
                try {
                    $ErrorActionPreference = 'Continue'
                    & $wrapper @gradleArguments 2>&1 |
                        Tee-Object -FilePath (Join-Path $artifactDirectory 'gradle.log')
                    $gradleExit = $LASTEXITCODE
                } finally { $ErrorActionPreference = $previousErrorAction }
                if ($gradleExit -ne 0) { throw "Gradle failed with exit code $gradleExit; see artifacts/android/$game/gradle.log" }
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
                "Supported ABIs: $Architectures. Target SDK 36 or greater; compile SDK 37."
            ) | Set-Content -Encoding utf8 -LiteralPath (Join-Path $artifactDirectory 'BUILD-NOTICE.txt')
            Write-Output "Built $apk and $aab"
        } finally { Pop-Location }
    }
} finally {
    if ($mappedDrive) { & subst.exe $mappedDrive /D }
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process') }
}
