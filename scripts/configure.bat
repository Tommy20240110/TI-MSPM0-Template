@echo off
setlocal enabledelayedexpansion

echo ========================================
echo  Configuration Tool
echo ========================================
echo.

:: Determine paths
set "SCRIPT_DIR=%~dp0"
for %%a in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fa"
for %%a in ("%PROJECT_ROOT%") do set "PROJECT_NAME=%%~nxa"
set "CSV_FILE=%SCRIPT_DIR%mspm0_chip_db.csv"

:: Template paths
set "TMPL_CMAKE_PRESETS=%PROJECT_ROOT%\.cmake\template\CMakePresets.json.template"
set "TMPL_CMAKE_USER_PRESETS=%PROJECT_ROOT%\.cmake\template\CMakeUserPresets.json.template"
set "TMPL_CPP_PROPERTIES=%PROJECT_ROOT%\.vscode\template\c_cpp_properties.json.template"
set "TMPL_LAUNCH=%PROJECT_ROOT%\.vscode\template\launch.json.template"
set "TMPL_TASKS=%PROJECT_ROOT%\.vscode\template\tasks.json.template"

:: Output paths
set "OUT_CMAKE_PRESETS=%PROJECT_ROOT%\CMakePresets.json"
set "OUT_CMAKE_USER_PRESETS=%PROJECT_ROOT%\CMakeUserPresets.json"
set "OUT_TOOLCHAIN=%PROJECT_ROOT%\.cmake\toolchain\toolchain.cmake"
set "OUT_CONFIG_INI=%SCRIPT_DIR%config.ini"

:: Ask for reconfigure
:ask_reconfig
set /p "RECONFIGURE=Do you want to reconfigure? (Y/N)[default: Y]: "
if /i "!RECONFIGURE!"=="" (
    echo Reconfiguring all files...
    echo.
    set "RECONFIG=1"
) else if /i "!RECONFIGURE!"=="Y" (
    echo Reconfiguring all files...
    echo.
    set "RECONFIG=1"
) else if /i "!RECONFIGURE!"=="N" (
    echo Checking existing configuration...
    echo.
    set "RECONFIG=0"
) else (
    echo Please enter Y or N, or press Enter for default.
    goto ask_reconfig
)

:: Check existing files if not reconfiguring
if !RECONFIG!==0 (
    call :CheckFiles
    if errorlevel 1 (
        echo Some files are missing. Starting reconfiguration...
        echo.
        set "RECONFIG=1"
    )
)

:: Collect or load configuration
if !RECONFIG!==1 (
    call :CollectConfig
    if errorlevel 1 (
        pause
        exit /b 1
    )
) else (
    call :LoadExistingConfig
)

:: Generate configuration files
if !RECONFIG!==1 (
    call :GenerateCMakePresets
    call :GenerateCMakeUserPresets
    call :GenerateToolchain
    call :GenerateConfigIni
    call :CopyStartupFile
    if errorlevel 1 echo WARNING: Startup file copy failed.
)

:: Ask for VS Code configuration
echo.
:ask_vscode
set /p "USE_VSCODE=Do you want to generate VS Code configuration? (Y/N)[default: Y]: "
if /i "!USE_VSCODE!"=="" (
    call :GenerateVSCode
) else if /i "!USE_VSCODE!"=="Y" (
    call :GenerateVSCode
) else if /i "!USE_VSCODE!"=="N" (
    echo Skipping VS Code configuration.
) else (
    echo Please enter Y or N, or press Enter for default.
    goto ask_vscode
)

echo.
echo ========================================
echo  Configuration Complete!
echo ========================================
echo.
pause
exit /b 0


::  CheckFiles - Check if all required output files exist
:CheckFiles
set "MISSING=0"
if not exist "%OUT_CMAKE_PRESETS%" (
    echo MISSING: CMakePresets.json
    set "MISSING=1"
)
if not exist "%OUT_CMAKE_USER_PRESETS%" (
    echo MISSING: CMakeUserPresets.json
    set "MISSING=1"
)
if not exist "%OUT_TOOLCHAIN%" (
    echo MISSING: toolchain.cmake
    set "MISSING=1"
)
if not exist "%OUT_CONFIG_INI%" (
    echo MISSING: config.ini
    set "MISSING=1"
)

if !MISSING!==0 (
    echo All files found!
    exit /b 0
) else (
    echo Some files missing.
    exit /b 1
)


::  LoadExistingConfig - Load configuration from existing files
:LoadExistingConfig
echo Loading existing configuration...
echo.

:: Load from config.ini
if exist "%OUT_CONFIG_INI%" (
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"SYSCFG_ROOT" "%OUT_CONFIG_INI%"`) do set "SYSCFG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"TI_SDK_ROOT" "%OUT_CONFIG_INI%"`) do set "TI_SDK_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"COMPILER_TYPE" "%OUT_CONFIG_INI%"`) do set "COMPILER_TYPE=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"LINK_DRIVER" "%OUT_CONFIG_INI%"`) do set "LINK_DRIVER=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"GCC_ROOT" "%OUT_CONFIG_INI%"`) do set "GCC_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"CLANG_ROOT" "%OUT_CONFIG_INI%"`) do set "CLANG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"TI_CLANG_ROOT" "%OUT_CONFIG_INI%"`) do set "TI_CLANG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"DEBUGGER_TYPE" "%OUT_CONFIG_INI%"`) do set "DEBUGGER_TYPE=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"GDB_PATH" "%OUT_CONFIG_INI%"`) do set "GDB_PATH=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"LLDB_ROOT" "%OUT_CONFIG_INI%"`) do set "LLDB_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"OPENOCD_ROOT" "%OUT_CONFIG_INI%"`) do set "OPENOCD_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"CHIP_MODEL" "%OUT_CONFIG_INI%"`)  do set "CHIP_MODEL=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"PROJECT_NAME" "%OUT_CONFIG_INI%"`) do set "PROJECT_NAME=%%a"
    echo Loaded from config.ini
)

:: Load CHIP_MODEL from CMakePresets.json (backup)
if exist "%OUT_CMAKE_PRESETS%" (
    for /f "usebackq tokens=*" %%a in (`findstr /c:"\"CHIP_MODEL\"" "%OUT_CMAKE_PRESETS%"`) do set "line=%%a"
    for /f tokens^=4^ delims^=^" %%b in ("!line!") do (
        set "tmp=%%b"
        set "tmp=!tmp:,=!"
        set "tmp=!tmp: =!"
        if not "!tmp!"=="" set "CHIP_MODEL=!tmp!"
    )
    echo Loaded CHIP_MODEL from CMakePresets.json
)

:: Load from CMakeUserPresets.json (fallback only, do NOT overwrite config.ini values)
if exist "%OUT_CMAKE_USER_PRESETS%" (
    if "!TI_SDK_ROOT!"=="" (
        for /f "usebackq tokens=2,* delims=: " %%a in (`findstr "TI_SDK_ROOT" "%OUT_CMAKE_USER_PRESETS%" ^| findstr "value"`) do (
            set "tmp=%%a"
            set "tmp=!tmp:"=!"
            set "tmp=!tmp:,=!"
            set "tmp=!tmp: =!"
            if "!tmp!" neq "" if "!TI_SDK_ROOT!"=="" set "TI_SDK_ROOT=!tmp!"
        )
    )
    if "!COMPILER_TYPE!"=="" (
        for /f "usebackq tokens=2,* delims=: " %%a in (`findstr "COMPILER_TYPE" "%OUT_CMAKE_USER_PRESETS%" ^| findstr "value"`) do (
            set "tmp=%%a"
            set "tmp=!tmp:"=!"
            set "tmp=!tmp:,=!"
            set "tmp=!tmp: =!"
            if "!tmp!" neq "" if "!COMPILER_TYPE!"=="" set "COMPILER_TYPE=!tmp!"
        )
    )
    if "!GCC_ROOT!"=="" (
        for /f "usebackq tokens=2,* delims=: " %%a in (`findstr "GCC_ROOT" "%OUT_CMAKE_USER_PRESETS%" ^| findstr "value"`) do (
            set "tmp=%%a"
            set "tmp=!tmp:"=!"
            set "tmp=!tmp:,=!"
            set "tmp=!tmp: =!"
            if "!tmp!" neq "" if "!GCC_ROOT!"=="" set "GCC_ROOT=!tmp!"
        )
    )
    if "!CLANG_ROOT!"=="" (
        for /f "usebackq tokens=2,* delims=: " %%a in (`findstr "CLANG_ROOT" "%OUT_CMAKE_USER_PRESETS%" ^| findstr "value"`) do (
            set "tmp=%%a"
            set "tmp=!tmp:"=!"
            set "tmp=!tmp:,=!"
            set "tmp=!tmp: =!"
            if "!tmp!" neq "" if "!CLANG_ROOT!"=="" set "CLANG_ROOT=!tmp!"
        )
    )
    if "!TI_CLANG_ROOT!"=="" (
        for /f "usebackq tokens=2,* delims=: " %%a in (`findstr "TI_CLANG_ROOT" "%OUT_CMAKE_USER_PRESETS%" ^| findstr "value"`) do (
            set "tmp=%%a"
            set "tmp=!tmp:"=!"
            set "tmp=!tmp:,=!"
            set "tmp=!tmp: =!"
            if "!tmp!" neq "" if "!TI_CLANG_ROOT!"=="" set "TI_CLANG_ROOT=!tmp!"
        )
    )
    echo Loaded from CMakeUserPresets.json
)

echo Existing configuration loaded.
exit /b 0


::  CollectConfig - Prompt user for all configuration values
:CollectConfig
echo Press Enter to keep the existing value (shown in brackets).

:: Pre-load existing values from config.ini as defaults
if exist "%OUT_CONFIG_INI%" (
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"SYSCFG_ROOT" "%OUT_CONFIG_INI%"`) do set "SYSCFG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"TI_SDK_ROOT" "%OUT_CONFIG_INI%"`) do set "TI_SDK_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"COMPILER_TYPE" "%OUT_CONFIG_INI%"`) do set "COMPILER_TYPE=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"LINK_DRIVER" "%OUT_CONFIG_INI%"`) do set "LINK_DRIVER=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"GCC_ROOT" "%OUT_CONFIG_INI%"`) do set "GCC_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"CLANG_ROOT" "%OUT_CONFIG_INI%"`) do set "CLANG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"TI_CLANG_ROOT" "%OUT_CONFIG_INI%"`) do set "TI_CLANG_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"DEBUGGER_TYPE" "%OUT_CONFIG_INI%"`) do set "DEBUGGER_TYPE=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"GDB_PATH" "%OUT_CONFIG_INI%"`) do set "GDB_PATH=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"LLDB_ROOT" "%OUT_CONFIG_INI%"`) do set "LLDB_ROOT=%%a"
    for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"OPENOCD_ROOT" "%OUT_CONFIG_INI%"`) do set "OPENOCD_ROOT=%%a"
)

:: === Step 1: TI Sysconfig Root ===
set /p "SYSCFG_ROOT=TI Sysconfig path [%SYSCFG_ROOT%]: "
if "%SYSCFG_ROOT%"=="" (
    echo ERROR: TI Sysconfig path cannot be empty!
    exit /b 1
)
set "SYSCFG_ROOT=%SYSCFG_ROOT:\=/%"

:: === Step 2: TI MSPM0 SDK Root ===
set /p "TI_SDK_ROOT=TI MSPM0 SDK path [%TI_SDK_ROOT%]: "
if "%TI_SDK_ROOT%"=="" (
    echo ERROR: TI SDK path cannot be empty!
    exit /b 1
)
set "TI_SDK_ROOT=%TI_SDK_ROOT:\=/%"

:: === Step 3: Compiler Type ===
:ask_compiler
set "COMPILER_CHOICE_DEFAULT=1"
if /i "!COMPILER_TYPE!"=="clang"   set "COMPILER_CHOICE_DEFAULT=2"
if /i "!COMPILER_TYPE!"=="ticlang" set "COMPILER_CHOICE_DEFAULT=3"
echo Select compiler:
echo   [1] GCC ARM ^(default^)
echo   [2] Clang/LLVM
echo   [3] TIClang
set /p "COMPILER_CHOICE=Enter choice [!COMPILER_CHOICE_DEFAULT!]: "
if "!COMPILER_CHOICE!"=="" set "COMPILER_CHOICE=!COMPILER_CHOICE_DEFAULT!"

if "!COMPILER_CHOICE!"=="1" (
    set "COMPILER_TYPE=gcc"
    set "LINK_DRIVER=gcc"
) else if "!COMPILER_CHOICE!"=="2" (
    set "COMPILER_TYPE=clang"
) else if "!COMPILER_CHOICE!"=="3" (
    set "COMPILER_TYPE=ticlang"
    set "LINK_DRIVER=ticlang"
) else (
    echo Please enter 1, 2, 3, or press Enter for default.
    goto ask_compiler
)
echo   Compiler: !COMPILER_TYPE!

:: === Step 4: Compiler-specific path ===
if "!COMPILER_TYPE!"=="gcc" (
    set /p "GCC_ROOT=GCC path [%GCC_ROOT%]: "
    if "!GCC_ROOT!"=="" (echo ERROR: GCC path cannot be empty. & exit /b 1)
    set "GCC_ROOT=!GCC_ROOT:\=/!"
    set "GDB_PATH=!GCC_ROOT!/bin/arm-none-eabi-gdb.exe"
) else if "!COMPILER_TYPE!"=="clang" (
    set /p "CLANG_ROOT=Clang/LLVM path [%CLANG_ROOT%]: "
    if "!CLANG_ROOT!"=="" (echo ERROR: Clang/LLVM path cannot be empty. & exit /b 1)
    set "CLANG_ROOT=!CLANG_ROOT:\=/!"
    set "TI_CLANG_ROOT="
) else (
    set /p "TI_CLANG_ROOT=TIClang path [%TI_CLANG_ROOT%]: "
    if "!TI_CLANG_ROOT!"=="" (echo ERROR: TIClang path cannot be empty. & exit /b 1)
    set "TI_CLANG_ROOT=!TI_CLANG_ROOT:\=/!"
    set "CLANG_ROOT="
)

:: === Step 5: Link Driver (Clang only) ===
if not "!COMPILER_TYPE!"=="clang" goto :step5_done

:ask_link_driver
set "LINK_DRIVER_DEFAULT=Y"
if /i "!LINK_DRIVER!"=="llvm" set "LINK_DRIVER_DEFAULT=N"
echo Use GCC as link driver? ^(Y/N^) [!LINK_DRIVER_DEFAULT!]
echo   Y = GCC link driver: -specs, newlib-nano, -lgcc -lc -lm
echo   N = LLVM link driver: clang/LLD, compiler-rt
set /p "LINK_DRIVER_INPUT="
if "!LINK_DRIVER_INPUT!"=="" set "LINK_DRIVER_INPUT=!LINK_DRIVER_DEFAULT!"
if /i "!LINK_DRIVER_INPUT!"=="Y" (
    set "LINK_DRIVER=gcc"
) else if /i "!LINK_DRIVER_INPUT!"=="N" (
    set "LINK_DRIVER=llvm"
) else (
    echo Please enter Y or N.
    goto ask_link_driver
)
echo   Link Driver: !LINK_DRIVER!
:step5_done

:: === Step 6: GCC path (if needed for link driver) ===
if "!LINK_DRIVER!"=="gcc" (
    if "!GCC_ROOT!"=="" (
        set /p "GCC_ROOT=GCC path [%GCC_ROOT%]: "
        if "!GCC_ROOT!"=="" (echo ERROR: GCC path cannot be empty. & exit /b 1)
        set "GCC_ROOT=!GCC_ROOT:\=/!"
    )
    if "!GDB_PATH!"=="" set "GDB_PATH=!GCC_ROOT!/bin/arm-none-eabi-gdb.exe"
) else (
    if not "!COMPILER_TYPE!"=="gcc" set "GCC_ROOT="
)

:: === Step 7: Debugger ===
:ask_debugger
set "DEBUGGER_CHOICE_DEFAULT=1"
if /i "!DEBUGGER_TYPE!"=="lldb" set "DEBUGGER_CHOICE_DEFAULT=2"
echo Select debugger:
echo   [1] GDB ^(default^)
echo   [2] LLDB
set /p "DEBUGGER_CHOICE=Enter choice [!DEBUGGER_CHOICE_DEFAULT!]: "
if "!DEBUGGER_CHOICE!"=="" set "DEBUGGER_CHOICE=!DEBUGGER_CHOICE_DEFAULT!"

if "!DEBUGGER_CHOICE!"=="1" (
    set "DEBUGGER_TYPE=gdb"
) else if "!DEBUGGER_CHOICE!"=="2" (
    set "DEBUGGER_TYPE=lldb"
) else (
    echo Please enter 1 or 2.
    goto ask_debugger
)
echo   Debugger: !DEBUGGER_TYPE!

:: === Step 8: Debugger path ===
if "!DEBUGGER_TYPE!"=="gdb" (
    if "!GDB_PATH!"=="" (
        set /p "GDB_PATH=GDB path [%GDB_PATH%]: "
        if "!GDB_PATH!"=="" (echo ERROR: GDB path cannot be empty. & exit /b 1)
        set "GDB_PATH=!GDB_PATH:\=/!"
        if "!GDB_PATH:gdb=!"=="!GDB_PATH!" (
            set "GDB_PATH=!GDB_PATH!/bin/arm-none-eabi-gdb.exe"
            echo   Auto-appended: !GDB_PATH!
        )
    )
    set "LLDB_ROOT="
) else (
    set /p "LLDB_ROOT=LLDB path [%LLDB_ROOT%]: "
    if "!LLDB_ROOT!"=="" (echo ERROR: LLDB path cannot be empty. & exit /b 1)
    set "LLDB_ROOT=!LLDB_ROOT:\=/!"
    set "GDB_PATH=!LLDB_ROOT!/bin/lldb"
)

:: === Step 9: OpenOCD Path ===
set /p "OPENOCD_ROOT=OpenOCD path [%OPENOCD_ROOT%]: "
if "%OPENOCD_ROOT%"=="" (
    echo ERROR: OpenOCD path cannot be empty!
    exit /b 1
)
set "OPENOCD_ROOT=%OPENOCD_ROOT:\=/%"

:: === Step 10: Chip Model ===
:: Pre-load chip model from config.ini (may be empty)
for /f "usebackq tokens=2 delims== " %%a in (`findstr /c:"CHIP_MODEL" "%OUT_CONFIG_INI%" 2^>nul`) do set "CHIP_MODEL=%%a"

set /p "CHIP_MODEL_INPUT=Enter chip model [%CHIP_MODEL%]: "

:: If user pressed Enter, use pre-loaded value
if "!CHIP_MODEL_INPUT!"=="" set "CHIP_MODEL_INPUT=!CHIP_MODEL!"

if "!CHIP_MODEL_INPUT!"=="" (
    echo ERROR: Chip model cannot be empty!
    exit /b 1
)

if not exist "%CSV_FILE%" (
    echo ERROR: Chip database not found at %CSV_FILE%!
    exit /b 1
)

set "CHIP_FOUND=0"
for /f "usebackq skip=1 tokens=1-6 delims=," %%a in ("%CSV_FILE%") do (
    if /i "%%a"=="!CHIP_MODEL_INPUT!" (
        set "CHIP_MODEL=%%a"
        set "CHIP_FAMILY=%%b"
        set "CORE=%%c"
        set "ARCH=%%d"
        set "FLOAT_ABI=%%e"
        set "STARTUP_FILE=%%f"
        set "CHIP_FOUND=1"
    )
)

if !CHIP_FOUND!==0 (
    echo ERROR: Chip model "!CHIP_MODEL_INPUT!" not found in database!
    echo Run the script again and enter a valid chip model.
    exit /b 1
)

echo Found chip configuration:
echo   CHIP_MODEL:    !CHIP_MODEL!
echo   CHIP_FAMILY:   !CHIP_FAMILY!
echo   CORE:          !CORE!
echo   ARCH:          !ARCH!
echo   FLOAT_ABI:     !FLOAT_ABI!
echo   STARTUP_FILE:  !STARTUP_FILE!
echo.

echo ========================================
echo  Configuration Summary
echo ========================================
echo   Compiler:      !COMPILER_TYPE!
echo   Link Driver:   !LINK_DRIVER!
echo   Debugger:      !DEBUGGER_TYPE!
echo ========================================

exit /b 0


::  GenerateCMakePresets
:GenerateCMakePresets
echo.
echo Generating CMakePresets.json...

if not exist "%TMPL_CMAKE_PRESETS%" (
    echo ERROR: Template not found: %TMPL_CMAKE_PRESETS%
    exit /b 1
)

call :SubFile "%TMPL_CMAKE_PRESETS%" "%OUT_CMAKE_PRESETS%"

if exist "%OUT_CMAKE_PRESETS%" (
    echo CMakePresets.json generated.
) else (
    echo ERROR: Failed to generate CMakePresets.json!
    exit /b 1
)
exit /b 0


::  GenerateCMakeUserPresets
:GenerateCMakeUserPresets
echo.
echo Generating CMakeUserPresets.json...

if not exist "%TMPL_CMAKE_USER_PRESETS%" (
    echo ERROR: Template not found: %TMPL_CMAKE_USER_PRESETS%
    exit /b 1
)

call :SubFile "%TMPL_CMAKE_USER_PRESETS%" "%OUT_CMAKE_USER_PRESETS%"

if exist "%OUT_CMAKE_USER_PRESETS%" (
    echo CMakeUserPresets.json generated.
) else (
    echo ERROR: Failed to generate CMakeUserPresets.json!
    exit /b 1
)
exit /b 0


::  GenerateToolchain - Select template by COMPILER_TYPE
:GenerateToolchain
echo.
echo Generating toolchain.cmake ^(!COMPILER_TYPE!^)...

:: Select template by compiler type
if "!COMPILER_TYPE!"=="gcc" (
    set "TMPL_TOOLCHAIN=%PROJECT_ROOT%\.cmake\template\toolchain.gcc.cmake.template"
) else if "!COMPILER_TYPE!"=="clang" (
    set "TMPL_TOOLCHAIN=%PROJECT_ROOT%\.cmake\template\toolchain.clang.cmake.template"
) else if "!COMPILER_TYPE!"=="ticlang" (
    set "TMPL_TOOLCHAIN=%PROJECT_ROOT%\.cmake\template\toolchain.ticlang.cmake.template"
) else (
    echo ERROR: Unknown COMPILER_TYPE '!COMPILER_TYPE!'!
    exit /b 1
)

if not exist "!TMPL_TOOLCHAIN!" (
    echo ERROR: Template not found: !TMPL_TOOLCHAIN!
    exit /b 1
)

set "TOOLCHAIN_DIR=%PROJECT_ROOT%\.cmake\toolchain"
if not exist "!TOOLCHAIN_DIR!" mkdir "!TOOLCHAIN_DIR!"

call :SubFile "!TMPL_TOOLCHAIN!" "%OUT_TOOLCHAIN%"

if exist "%OUT_TOOLCHAIN%" (
    echo toolchain.cmake generated.
) else (
    echo ERROR: Failed to generate toolchain.cmake!
    exit /b 1
)
exit /b 0


::  GenerateConfigIni
:GenerateConfigIni
echo.
echo Generating config.ini...

> "%OUT_CONFIG_INI%" echo [Config]
>>"%OUT_CONFIG_INI%" echo SYSCFG_ROOT = !SYSCFG_ROOT!
>>"%OUT_CONFIG_INI%" echo TI_SDK_ROOT = !TI_SDK_ROOT!
>>"%OUT_CONFIG_INI%" echo COMPILER_TYPE = !COMPILER_TYPE!
>>"%OUT_CONFIG_INI%" echo LINK_DRIVER = !LINK_DRIVER!
>>"%OUT_CONFIG_INI%" echo GCC_ROOT = !GCC_ROOT!
>>"%OUT_CONFIG_INI%" echo CLANG_ROOT = !CLANG_ROOT!
>>"%OUT_CONFIG_INI%" echo TI_CLANG_ROOT = !TI_CLANG_ROOT!
>>"%OUT_CONFIG_INI%" echo DEBUGGER_TYPE = !DEBUGGER_TYPE!
>>"%OUT_CONFIG_INI%" echo GDB_PATH = !GDB_PATH!
>>"%OUT_CONFIG_INI%" echo LLDB_ROOT = !LLDB_ROOT!
>>"%OUT_CONFIG_INI%" echo OPENOCD_ROOT = !OPENOCD_ROOT!
>>"%OUT_CONFIG_INI%" echo CHIP_MODEL = !CHIP_MODEL!
>>"%OUT_CONFIG_INI%" echo PROJECT_NAME = !PROJECT_NAME!

if exist "%OUT_CONFIG_INI%" (
    echo config.ini generated.
) else (
    echo ERROR: Failed to generate config.ini!
    exit /b 1
)
exit /b 0


::  CopyStartupFile - Copy startup file from SDK to Core/Startup/
:CopyStartupFile
echo.
echo Copying startup file...

:: Convert to backslashes for Windows file operations
set "SDK_BS=!TI_SDK_ROOT:/=\!"

:: GCC/Clang use GCC startup; TIClang uses its own
if "!COMPILER_TYPE!"=="ticlang" (
    set "STARTUP_SRC=!SDK_BS!\source\ti\devices\msp\m0p\startup_system_files\ticlang\!STARTUP_FILE!_ticlang.c"
    set "STARTUP_DST=%PROJECT_ROOT%\Core\Startup\!STARTUP_FILE!_ticlang.c"
) else (
    set "STARTUP_SRC=!SDK_BS!\source\ti\devices\msp\m0p\startup_system_files\gcc\!STARTUP_FILE!_gcc.c"
    set "STARTUP_DST=%PROJECT_ROOT%\Core\Startup\!STARTUP_FILE!_gcc.c"
)

echo   Source: !STARTUP_SRC!

if not exist "!STARTUP_SRC!" (
    echo WARNING: Startup file not found at:
    echo   !STARTUP_SRC!
    echo Please check that TI_SDK_ROOT points to a valid MSPM0 SDK installation.
    exit /b 1
)

set "STARTUP_DIR=%PROJECT_ROOT%\Core\Startup"
if not exist "!STARTUP_DIR!" mkdir "!STARTUP_DIR!"

:: Clean old startup files before copying new one
if exist "!STARTUP_DIR!\startup_*.c" del /Q "!STARTUP_DIR!\startup_*.c"

copy /Y "!STARTUP_SRC!" "!STARTUP_DST!" >nul
if exist "!STARTUP_DST!" (
    echo   Copied.
) else (
    echo WARNING: Failed to copy startup file!
)
exit /b 0


::  GenerateVSCode - Generate .vscode/c_cpp_properties.json from template
:GenerateVSCode
echo.
echo Generating VS Code configuration...

set "VSCODE_DIR=%PROJECT_ROOT%\.vscode"
if not exist "!VSCODE_DIR!" mkdir "!VSCODE_DIR!"

:: Build device define (e.g., __MSPM0G3507__)
set "DEVICE_DEFINE_UPPER=!CHIP_MODEL!"
for %%c in (a-A b-B c-C d-D e-E f-F g-G h-H i-I j-J k-K l-L m-M n-N o-O p-P q-Q r-R s-S t-T u-U v-V w-W x-X y-Y z-Z) do (
    for /f "tokens=1,* delims=-" %%x in ("%%c") do (
        set "DEVICE_DEFINE_UPPER=!DEVICE_DEFINE_UPPER:%%x=%%y!"
    )
)
set "DEVICE_DEFINE=__!DEVICE_DEFINE_UPPER!__"

:: c_cpp_properties.json
echo   - c_cpp_properties.json
set "OUT_CPP=!VSCODE_DIR!\c_cpp_properties.json"
if not exist "%TMPL_CPP_PROPERTIES%" (
    echo ERROR: Template not found: %TMPL_CPP_PROPERTIES%
    exit /b 1
)

call :SubFile "%TMPL_CPP_PROPERTIES%" "%OUT_CPP%"

if not exist "%OUT_CPP%" (
    echo ERROR: Failed to generate c_cpp_properties.json!
    exit /b 1
)

:: launch.json
echo   - launch.json
set "OUT_LAUNCH=!VSCODE_DIR!\launch.json"
if not exist "%TMPL_LAUNCH%" (
    echo WARNING: Template not found: %TMPL_LAUNCH%
) else (
    call :SubFile "%TMPL_LAUNCH%" "%OUT_LAUNCH%"
)

:: tasks.json
echo   - tasks.json
set "OUT_TASKS=!VSCODE_DIR!\tasks.json"
if not exist "%TMPL_TASKS%" (
    echo WARNING: Template not found: %TMPL_TASKS%
) else (
    call :SubFile "%TMPL_TASKS%" "%OUT_TASKS%"
)

echo VS Code configuration generated.
exit /b 0


::  SubFile - Copy template, replacing @VAR@ tokens
::  %1 = template path, %2 = output path
:SubFile
set "tmpl=%~1"
set "out=%~2"

:: Try to delete old file to detect write-lock
if exist "%out%" (
    del "%out%" 2>nul
    if exist "%out%" (
        echo ERROR: Cannot overwrite %out% - file may be locked by another program.
        echo Please close the file in open editors and try again.
        exit /b 1
    )
)

for /f "usebackq tokens=1,* delims=:" %%a in (`findstr /n "^" "%tmpl%"`) do (
    set "line=%%b"
    if "!line!"=="" (
        >>"%out%" echo(
    ) else (
        set "line=!line:@CHIP_MODEL@=%CHIP_MODEL%!"
        set "line=!line:@CHIP_FAMILY@=%CHIP_FAMILY%!"
        set "line=!line:@CORE@=%CORE%!"
        set "line=!line:@ARCH@=%ARCH%!"
        set "line=!line:@FLOAT_ABI@=%FLOAT_ABI%!"
        set "line=!line:@TI_SDK_ROOT@=%TI_SDK_ROOT%!"
        set "line=!line:@COMPILER_TYPE@=%COMPILER_TYPE%!"
        set "line=!line:@LINK_DRIVER@=%LINK_DRIVER%!"
        set "line=!line:@GCC_ROOT@=%GCC_ROOT%!"
        set "line=!line:@CLANG_ROOT@=%CLANG_ROOT%!"
        set "line=!line:@TI_CLANG_ROOT@=%TI_CLANG_ROOT%!"
        set "line=!line:@DEBUGGER_TYPE@=%DEBUGGER_TYPE%!"
        set "line=!line:@GDB_PATH@=%GDB_PATH%!"
        set "line=!line:@LLDB_ROOT@=%LLDB_ROOT%!"
        set "line=!line:@OPENOCD_ROOT@=%OPENOCD_ROOT%!"
        set "line=!line:@PROJECT_NAME@=%PROJECT_NAME%!"
        set "line=!line:@STARTUP_FILE@=%STARTUP_FILE%!"
        set "line=!line:${config:ti.sdk.root}=%TI_SDK_ROOT%!"
        if defined DEVICE_DEFINE (
            set "line=!line:Please fill in your device macro definition such as __MSPM0G3507__=%DEVICE_DEFINE%!"
        )
        >>"%out%" echo !line!
    )
)

:: Verify output was successfully written
if not exist "%out%" (
    echo ERROR: Failed to write %out%
    exit /b 1
)
exit /b 0
