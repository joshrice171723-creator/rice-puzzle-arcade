param(
    [ValidateSet('Play','Test','Android','Windows')][string]$Action = 'Play',
    [string]$Godot = "$env:LOCALAPPDATA/NightfallTools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$project = Join-Path $repo 'apps/nightfall-godot'
$output = Join-Path $repo 'artifacts/nightfall-godot'
if (!(Test-Path -LiteralPath $Godot)) { throw 'Godot 4.7.2 is required. Pass -Godot with its portable executable path.' }
function Invoke-Godot([string[]]$Arguments) {
    $isTest = $Arguments -contains '--script'
    if ($isTest) { $Arguments += @('--quit-after', '6000') }
    $scriptFailure = $false
    $passedSummary = $false
    & $Godot @Arguments 2>&1 | ForEach-Object {
        $line = "$_"
        if ($line -match 'SCRIPT ERROR:|Parse Error:|Failed to load script') { $scriptFailure = $true }
        if ($line -match 'checks, 0 failures') { $passedSummary = $true }
        Write-Output $line
    }
    if ($LASTEXITCODE -ne 0 -or $scriptFailure -or ($isTest -and !$passedSummary)) {
        throw "Godot verification failed (exit $LASTEXITCODE, script error $scriptFailure, passed summary $passedSummary)"
    }
}
if ($Action -eq 'Test') {
    Invoke-Godot @('--headless','--path',$project,'--script','tests/run_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/combat_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/combat_progression_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/mission_one_presentation_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/combat_training_ui_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/magic_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/specialization_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/field_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/profile_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/loot_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/defenses_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/reward_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/ui_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/power_ui_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/haven_ui_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/haven_product_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/progression_tools_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/equipment_workshop_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/zone_one_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/daily_progress_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/gear_popup_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/menu_motion_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/class_showcase_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/expedition_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/salvage_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/preparation_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/mastery_test.gd')
    Invoke-Godot @('--headless','--path',$project,'--script','tests/hud_layout_test.gd')
    exit
}
if ($Action -eq 'Play') {
    & $Godot --path $project
    exit $LASTEXITCODE
}
New-Item -ItemType Directory -Force $output | Out-Null
if ($Action -eq 'Android') {
    $env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
    $env:ANDROID_HOME = "$env:LOCALAPPDATA/Android/Sdk"
    $template = "$env:APPDATA/Godot/export_templates/4.7.2.stable/android_source.zip"
    $build = Join-Path $project 'android/build'
    if (!(Test-Path "$build/build.gradle")) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($template, $build)
    }
    Set-Content (Join-Path $project 'android/.gdignore') ''
    $properties = Get-Content "$build/gradle.properties" -Raw
    $properties = $properties.Replace('-Xmx4536m', '-Xmx1536m')
    if ($properties -notmatch 'org.gradle.workers.max') { $properties += "`norg.gradle.workers.max=2`n" }
    if ($properties -notmatch 'kotlin.compiler.execution.strategy') { $properties += "`nkotlin.compiler.execution.strategy=in-process`n" }
    Set-Content "$build/gradle.properties" $properties -NoNewline
    # Reuse the installed NDK; this build packages precompiled Godot libraries.
    $config = Get-Content "$build/config.gradle" -Raw
    $config = $config.Replace("'29.0.14206865'", "'27.1.12297006'")
    # Ads 25.5 ships Kotlin 2.3 metadata; match it rather than suppressing checks.
    $config = $config.Replace("'2.1.21'", "'2.3.20'")
    Set-Content "$build/config.gradle" $config -NoNewline
    $source = Join-Path $build 'src/main/java/com/joshuarice/nightfallproof'
    New-Item -ItemType Directory -Force $source | Out-Null
    Copy-Item "$project/native/NightfallAds.kt" $source
    Set-Content (Join-Path $project 'android/.build_version') '4.7.2.stable' -NoNewline
    Invoke-Godot @('--headless','--path',$project,'--export-debug','Android proof','--quit')
    & "$build/gradlew.bat" --stop
} else {
    Invoke-Godot @('--headless','--path',$project,'--export-debug','Windows proof','--quit')
}
