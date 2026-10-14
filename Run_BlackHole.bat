@echo off
cd /d "%~dp0"
set "GODOT_EXE=%~dp0..\..\Godot_v4.6.3-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Open project.godot with Godot 4.6 or place the Godot executable on Desktop.
  pause
  exit /b 1
)
if not exist "%~dp0.godot\imported" start "Import Black Hole" /wait "%GODOT_EXE%" --headless --editor --path "%~dp0." --import --log-file "%~dp0.runtime\import.log"
start "Black Hole" "%GODOT_EXE%" --path "%~dp0." --log-file "%~dp0.runtime\run.log"