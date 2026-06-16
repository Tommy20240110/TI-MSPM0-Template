@echo off

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

set SYSCFG_ROOT=%~3
if "%SYSCFG_ROOT%"=="" (
    echo Sysconfig installation directory not provided
    exit
)

set SDK_ROOT=%~4
if "%SDK_ROOT%"=="" (
    echo SDK installation directory not provided
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
if not exist "%SYSCFG_ROOT%\sysconfig_cli.bat" (
    echo Couldn't find Sysconfig Tool
    exit
)
echo Using Sysconfig Tool from %SYSCFG_ROOT%\sysconfig_cli.bat%

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
call "%SYSCFG_ROOT%\sysconfig_cli.bat" -o "%PROJ_ROOT%\.ti\generate" -s "%SDK_ROOT%\.metadata\product.json" --compiler gcc "%SYSCFG_FILE%"

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

echo File organization completed!
