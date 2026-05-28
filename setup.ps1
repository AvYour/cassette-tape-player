# Run this script after installing Flutter SDK (https://docs.flutter.dev/get-started/install/windows)
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"

Write-Host "Backing up source files..." -ForegroundColor Cyan
Copy-Item -Path "lib" -Destination "lib_src_backup" -Recurse -Force
Copy-Item -Path "pubspec.yaml" -Destination "pubspec.yaml.bak" -Force
Copy-Item -Path ".env" -Destination ".env.bak" -Force

Write-Host "Generating Flutter project scaffold..." -ForegroundColor Cyan
flutter create . --project-name cassette_tape_player --platforms android --org com.example 2>&1 | Out-Null

Write-Host "Restoring source files..." -ForegroundColor Cyan
Remove-Item -Path "lib" -Recurse -Force
Rename-Item -Path "lib_src_backup" -NewName "lib"
Copy-Item -Path "pubspec.yaml.bak" -Destination "pubspec.yaml" -Force
Copy-Item -Path ".env.bak" -Destination ".env" -Force
Remove-Item "pubspec.yaml.bak" -Force
Remove-Item ".env.bak" -Force

Write-Host "Patching android/app/build.gradle..." -ForegroundColor Cyan
$buildGradlePath = "android\app\build.gradle"
$bg = Get-Content $buildGradlePath -Raw
$bg = $bg -replace 'minSdk\s*=?\s*\d+', 'minSdk 21'
$bg = $bg -replace 'targetSdk\s*=?\s*\d+', 'targetSdk 34'
$bg = $bg -replace 'compileSdk\s*=?\s*\d+', 'compileSdk 34'
if ($bg -notmatch 'appAuthRedirectScheme') {
    $bg = $bg -replace '(defaultConfig\s*\{)', "`$1`n        manifestPlaceholders += ['appAuthRedirectScheme': 'cassetteplayer']"
}
Set-Content -Path $buildGradlePath -Value $bg

Write-Host "Patching AndroidManifest.xml..." -ForegroundColor Cyan
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$mf = Get-Content $manifestPath -Raw
if ($mf -notmatch 'INTERNET') {
    $mf = $mf -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>`n    <uses-permission android:name=`"android.permission.CHANGE_NETWORK_STATE`"/>"
}
$spotifyActivity = @'
        <activity
            android:name="com.spotify.sdk.android.auth.LoginActivity"
            android:theme="@android:style/Theme.Translucent.NoTitleBar"
            android:exported="true" />
'@
if ($mf -notmatch 'LoginActivity') {
    $mf = $mf -replace '(\s*</application>)', "`n$spotifyActivity`$1"
}
Set-Content -Path $manifestPath -Value $mf

Write-Host "Installing Flutter packages..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "Done! Next steps:" -ForegroundColor Green
Write-Host "  1. Open .env and fill in your Spotify Client ID from developer.spotify.com"
Write-Host "  2. Add 'cassetteplayer://callback' as a Redirect URI in your Spotify app settings"
Write-Host "  3. Connect an Android device (API 21+) or start an emulator"
Write-Host "  4. Run: flutter run"
