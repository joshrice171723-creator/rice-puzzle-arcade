# Android builds

Each game has its own Expo project and Android application ID. Native AdMob requires an Android development or standalone build; Expo Go does not load this SDK.

## Local prerequisites

- Node.js 24 and pnpm 11.25.0, as pinned in `package.json`.
- JDK 17 on PATH with `JAVA_HOME` pointing to that JDK. The [Expo SDK 58 Android build image](https://docs.expo.dev/build-reference/infrastructure/) uses Java 17.
- Android SDK with `ANDROID_HOME` configured, platform API 37, Build Tools 37.0.0, NDK 27.1.12297006 and CMake 3.22.1. These versions come from the installed Expo/React Native Gradle configuration. App target SDK is 36 and minimum SDK is 24.
- Ample disk space for dependencies, Gradle caches, Android toolchains and all three outputs. A full drive prevents reliable installation and native compilation.
- Existing SDK licenses accepted by the SDK owner. Installing additional SDK components may ask for their terms.

From the repository root:

```powershell
pnpm install --frozen-lockfile
pnpm typecheck
pnpm test
./scripts/build-android.ps1 -App all
```

Use `-App grid-foundry`, `-App merge-drift` or `-App color-cascade` to build one app. Add `-Architectures arm64-v8a` for a smaller phone-only build. PowerShell 7 works on Windows, Linux and macOS. The script generates the native Android folder through Expo Prebuild, validates API targeting and Google's test App ID, then builds a standalone APK and AAB with the Gradle wrapper. Native folders are generated and ignored by Git; keep lasting native configuration in Expo config plugins.

On Windows, the script can discover Android Studio's bundled JDK and the default local Android SDK if environment variables are unset. It temporarily maps a free drive letter to this repository and applies `scripts/windows-cmake.gradle`. That limits native object paths to 240 characters using [CMake's path hashing](https://cmake.org/cmake/help/latest/variable/CMAKE_OBJECT_PATH_MAX.html), avoiding the Windows Ninja 260-character failure. The mapping and process environment are restored on exit. It does not change the registry or replace SDK tools. Existing dependencies must resolve through the hoisted root `node_modules`; stale per-app dependency links from an earlier isolated installation can defeat the shorter path.

Outputs for each game:

```text
artifacts/android/<game>/<game>-internal-test.apk
artifacts/android/<game>/<game>-internal-test.aab
artifacts/android/<game>/SHA256SUMS.txt
artifacts/android/<game>/gradle.log
artifacts/android/<game>/BUILD-NOTICE.txt
```

These builds use official Google sample ads and Expo's generated development signing key. They run without Metro. They are **internal test artifacts**; the AAB proves native bundling when the build succeeds and must not be submitted as the production Play release. Included ABIs are arm64-v8a for modern phones and x86_64 for Android emulators.

Install a generated APK on an attached device or running emulator:

```powershell
adb devices
adb install -r ./artifacts/android/grid-foundry/grid-foundry-internal-test.apk
adb shell am start -n com.joshuarice.gridfoundry/.MainActivity
```

Repeat with `com.joshuarice.mergedrift` or `com.joshuarice.colorcascade` and the corresponding artifact. An APK build alone does not demonstrate device acceptance: verify cold start, real touch controls, persistence, lifecycle pause, native test-ad label and earned/dismissed reward behavior on the installed build. Record the artifact hash and device details with that evidence.

## Hosted native build

The manually dispatched **Internal Android artifacts** GitHub Actions workflow compiles each app on Ubuntu using the same script. Each app produces a separate workflow artifact containing its APK, AAB, hashes, notice and Gradle log. Failure logs are uploaded when available. This workflow does not publish apps or initialize any Play, AdMob or EAS account, and has no publishing credentials.

The workflow is manual to avoid automatically starting expensive native builds. Check the repository owner's available Actions allowance before dispatching; this project does not authorize purchasing runner minutes. A committed workflow is not a passed native build. Only a successful run and its downloadable artifacts provide that evidence.

## Production publishing

Each app includes an EAS production profile for an owner-controlled release. The production configuration deliberately refuses Google's sample IDs, missing real IDs, an implicit ads mode or an unapproved audience/disclosure review. Review `.env.example`, `docs/AD_INTEGRATION.md` and `docs/RELEASE_CHECKLIST.md` for the required per-app values and external gates.

A Play release additionally needs the owner's stable upload signing key, version management, Play App Signing setup, approved disclosures and publishing access. Keep credentials and signing keys outside Git. Native debug signing and the internal build script are insufficient for production. Do not claim a signed Play release, accepted store build or paid ad serving until each has its own evidence.

Current build/test outcomes and hardware limitations belong in `docs/TEST_RESULTS.md` and `STATUS.md`; this document describes the reproducible procedure.


Existing native projects are reused by default. After changing Expo app configuration or native plugins, pass `-RegenerateNative` to regenerate them. Avoid package installation while Gradle is running: replacing a dependency can remove its generated classes mid-build. Windows library codegen tasks use the physical repository path; the app uses the short mapped drive for CMake.

The Windows build explicitly tracks shared `packages/` sources as inputs to the app's JavaScript bundle, so shared UI/ad fixes invalidate cached bundles. Internal test artifacts disable code/resource shrinking to shorten iteration; this does not change the separate production configuration.

## Local virtual phone (October 18 setup)

The Windows host now has the official Google APIs Android 11 / API 30 x86_64 image and an AVD named `Arcade_QA_API30` (Pixel 2 profile). WHPX hardware acceleration passed its check. No cellular service is needed; network requests still use the host connection and its filtering.

Start the AVD with Android Studio Device Manager, or run:

```powershell
& "$env:LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd Arcade_QA_API30 -no-snapshot -memory 1536
```

Build with both architectures for phone and emulator compatibility:

```powershell
./scripts/build-android.ps1 -App all -Architectures 'arm64-v8a,x86_64'
```

Wait for `adb shell getprop sys.boot_completed` to return `1` before installing. An emulator can appear in `adb devices` before Android's package manager is ready. First boot may take longer while native builds are running.

Command-line tools are under `%LOCALAPPDATA%/Android/Sdk/cmdline-tools/latest`. This version's sdkmanager wrapper delegates to Android CLI; use the direct CLI when installing semicolon-delimited image package IDs. All downloaded components came from Google's official SDK repository. An installed or booted emulator is not proof that ad requests or reward callbacks succeeded.
