@ECHO OFF

SET CURRENT_DIR=%CD%
for %%* in (.) do set PROJECT_NAME=%%~n*

SET DATA_DIR=%CURRENT_DIR%/../%PROJECT_NAME%_data/win32
FOR /F "delims=" %%F IN ("%DATA_DIR%") DO SET "DATA_DIR=%%~fF"

SET REPO_DIR=%SR_EXE_DIR%/../../
FOR /F "delims=" %%F IN ("%REPO_DIR%") DO SET "REPO_DIR=%%~fF"

CALL "%SR_EXE_DIR%/win64/dev/stingray_win64_dev_x64.exe" --source-dir %CURRENT_DIR% --data-dir %DATA_DIR% --map-source-dir core %REPO_DIR% --compile

if errorlevel 1 (
   echo
   echo "Compilation failed (%errorlevel%)!"
   exit /b %errorlevel%
)
