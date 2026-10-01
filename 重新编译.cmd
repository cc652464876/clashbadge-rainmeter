@echo off
setlocal
cd /d "%~dp0ClashMode\@Resources"
if errorlevel 1 goto failed
set "BADGE_CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%BADGE_CSC%" set "BADGE_CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%BADGE_CSC%" (
  echo .NET Framework C# compiler was not found.
  goto failed
)
"%BADGE_CSC%" /nologo /optimize+ /target:exe /out:"ClashBadgeControl.exe" "ClashBadgeControl.cs"
if errorlevel 1 goto failed
echo Build completed. Refresh the Rainmeter skin.
pause
exit /b 0
:failed
echo Build failed. The source files have been kept.
pause
exit /b 1
