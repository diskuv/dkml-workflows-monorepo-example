@ECHO OFF

REM The OCaml dkml-base-compiler will compile fine but any other
REM packages (ocamlbuild, etc.) which
REM need a native compiler will fail without the MSVC compiler in the
REM PATH. There isn't a `with-dkml.exe` alternative available at
REM this stage of the GitHub workflow.
call "%VS_DIR%\Common7\Tools\VsDevCmd.bat" -no_logo -host_arch=%vsstudio_hostarch% -arch=%vsstudio_arch% -vcvars_ver=%VS_VCVARSVER% -winsdk=%VS_WINSDKVER%
if %ERRORLEVEL% neq 0 (
    echo.
    echo.The "%VS_DIR%\Common7\Tools\VsDevCmd.bat" command failed
    echo.with exit code %ERRORLEVEL%.
    echo.
    exit /b %ERRORLEVEL%
)

REM VsDevCmd.bat turns off echo; be explicit if we want it on or off
@echo OFF

REM MSVC environment variables in Unix format.
echo %PATH% > .ci\sd4\msvcpath
