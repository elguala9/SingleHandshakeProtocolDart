@echo off
echo Installing dependencies for all packages...

cd packages\types
echo Installing types...
call dart pub get

cd ..\interfaces
echo Installing interfaces...
call dart pub get

cd ..\implementations
echo Installing implementations...
call dart pub get

cd ..\tests
echo Installing tests...
call dart pub get

cd ..\..
echo All packages installed successfully!
