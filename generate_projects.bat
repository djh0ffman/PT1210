@echo off

set BUILD_DIR_DEBUG=build-debug
set BUILD_DIR_RELEASE=build-release
set TOOLCHAIN_FILE=cmake/amiga-gcc-toolchain.cmake
set GENERATOR="Unix Makefiles"

:: Look for GNU Make
where make /q || (
	echo Couldn't find GNU Make in your PATH.
	echo Add the amiga-gcc\bin directory to your PATH to use its bundled version of GNU Make.
	exit /b %ERRORLEVEL%
)

:: Create folders
if not exist %BUILD_DIR_DEBUG% md %BUILD_DIR_DEBUG%
if not exist %BUILD_DIR_RELEASE% md %BUILD_DIR_RELEASE%

:: Generate projects
cmake . -B%BUILD_DIR_DEBUG% -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN_FILE% -G%GENERATOR% %* || goto done
cmake . -B%BUILD_DIR_RELEASE% -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN_FILE% -G%GENERATOR% %* || goto done

:done
:: Pause if launched via double-click
if %0 == "%~0" pause
exit /b %ERRORLEVEL%
