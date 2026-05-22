@echo off

:: Change these paths to point to the location of the sysconfig_cli.bat file and the SDK on your machine
set SYSCFG_PATH=D:\Programs\DevTools\TI\Sysconfig\sysconfig_cli.bat
set SDK_ROOT=D:\Programs\DevTools\TI\mspm0_sdk_2_10_00_04

:: Check arguments
set PROJ_ROOT=%~1
if "%PROJ_ROOT%"=="" (
    echo Project directory not provided
    exit
)

set SYSCFG_NAME=%~2
if "%SYSCFG_NAME%"=="" (
    echo .syscfg file name not provided
    exit
)

:: Find and rename the syscfg file
for /r "%PROJ_ROOT%" %%f in (*.syscfg) do (
    ren "%%f" "%SYSCFG_NAME%.syscfg"
    set SYSCFG_FILE=%%f
)
if not defined SYSCFG_FILE (
    echo Couldn't find .syscfg file
    exit
)

:: Search for the sysconfig_cli.bat
if not exist "%SYSCFG_PATH%" (
    echo Couldn't find Sysconfig Tool
    exit
)

echo Using Sysconfig Tool from %SYSCFG_PATH%

:: Search for the root of the SDK by going up one directory
:: However, if we don't find it after 5 times then give up
set iter=0
:sdk_search_loop
if exist "%SDK_ROOT%\.metadata\product.json" (
    goto sdk_search_exit
) else if %iter% geq 5 (
	echo Couldn't find .metadata\product.json
    exit
) else (
	set /a iter=%iter%+1
	set SDK_ROOT=%SDK_ROOT%..\
	goto sdk_search_loop
)
:sdk_search_exit

if exist "%PROJ_ROOT%\.ti\generate" (
    rd /s /q "%PROJ_ROOT%\.ti\generate"
)

:: Here, the "call" keyword needs to be used to prevent the script from prematurely exiting
call %SYSCFG_PATH% -o "%PROJ_ROOT%\.ti\generate" -s "%SDK_ROOT%\.metadata\product.json" --compiler gcc "%SYSCFG_FILE%"

:: User's configuration
set SYSCFG_OUTPUT_DIR=%PROJ_ROOT%\.ti\generate
if not exist "%SYSCFG_OUTPUT_DIR%" (
    echo Couldn't find Sysconfig output directory
    exit
)

:: Move .c files to Core/Src
set CORE_SRC_DIR=%PROJ_ROOT%\Core\Src
if exist "%SYSCFG_OUTPUT_DIR%\*.c" (
    if not exist "%CORE_SRC_DIR%" mkdir "%CORE_SRC_DIR%"
    move /Y "%SYSCFG_OUTPUT_DIR%\*.c" "%CORE_SRC_DIR%\" >nul 2>&1
) else (
    echo Couldn't find .c files in %SYSCFG_OUTPUT_DIR%
    exit
)

:: Move .h files to Core/Inc
set CORE_INC_DIR=%PROJ_ROOT%\Core\Inc
if exist "%SYSCFG_OUTPUT_DIR%\*.h" (
    if not exist "%CORE_INC_DIR%" mkdir "%CORE_INC_DIR%"
    move /Y "%SYSCFG_OUTPUT_DIR%\*.h" "%CORE_INC_DIR%\" >nul 2>&1
) else (
    echo Couldn't find .h files in %SYSCFG_OUTPUT_DIR%
    exit
)

:: TODO: Search for the essential files and add them to the PATH
set CMSIS_SRC_DIR=%SDK_ROOT%\source\third_party\CMSIS\Core\Include
set CMSIS_DST_DIR=%PROJ_ROOT%\Drivers\third_party\CMSIS\Core\Include
if exist "%CMSIS_SRC_DIR%" (
    if not exist "%CMSIS_DST_DIR%" mkdir "%CMSIS_DST_DIR%"
    xcopy /Y /E "%CMSIS_SRC_DIR%\*" "%CMSIS_DST_DIR%\" >nul 2>&1
) else (
    echo WARNING: CMSIS source not found at %CMSIS_SRC_DIR%
    exit
)

echo File organization completed!