@echo off
echo 🚀 Building APK...

:: Build the APK (Flutter will output it to default location)
flutter build apk

:: Define source and destination paths
set "SRC=build\app\outputs\flutter-apk\app-release.apk"
set "DEST=apk\app-release.apk"

:: Make sure apk directory exists
if not exist "apk" (
    mkdir apk
)

:: Copy the APK to apk/
echo 📁 Copying APK to %DEST%
copy /Y "%SRC%" "%DEST%"

echo ✅ APK copied successfully to apk\app-release.apk
pause
