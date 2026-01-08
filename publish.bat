@echo off
REM SHSP Packages Publication Script for Windows
REM This script publishes all SHSP packages in the correct order

echo 🚀 Starting SHSP packages publication process...
echo.

echo 📦 Step 1: Publishing shsp_types...
cd packages\types
echo Validating shsp_types package...
dart pub publish --dry-run
echo.
echo Ready to publish shsp_types. This package has no dependencies on other SHSP packages.
pause
dart pub publish

echo.
echo ⏳ Waiting for shsp_types to be available on pub.dev...
timeout /t 30 /nobreak > nul

echo.
echo 📦 Step 2: Publishing shsp_interfaces...
cd ..\interfaces
echo Validating shsp_interfaces package...
dart pub get
dart pub publish --dry-run
echo.
echo Ready to publish shsp_interfaces. This package depends on shsp_types.
pause
dart pub publish

echo.
echo ⏳ Waiting for shsp_interfaces to be available on pub.dev...
timeout /t 30 /nobreak > nul

echo.
echo 📦 Step 3: Publishing shsp_implementations...
cd ..\implementations
echo Validating shsp_implementations package...
dart pub get
dart pub publish --dry-run
echo.
echo Ready to publish shsp_implementations. This package depends on shsp_types and shsp_interfaces.
pause
dart pub publish

echo.
echo 🎉 All SHSP packages have been published successfully!
echo.
echo 📋 Published packages:
echo    • https://pub.dev/packages/shsp_types
echo    • https://pub.dev/packages/shsp_interfaces
echo    • https://pub.dev/packages/shsp_implementations
echo.
echo ✨ Publication complete!
pause