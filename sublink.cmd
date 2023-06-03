::: sublink
::: =======
:::
::: A simple tool to keep track of locally overridden Sublime syntax packages.
:::
::: Usage: sublink [PACKAGE]   Link or unlink the given package
:::        sublink             List all created package overrides
:::
::: Arguments:
:::   [PACKAGE]         Sublime syntax package to install or remove
:::
::: Options:
:::   /?, -h, --help    Print help
:::
::: Variables:
:::   SUBLIME_PATH      Absolute path to a Sublime data directory
:::                     (default: '%APPDATA%\Sublime Text')
:::

@setlocal DisableDelayedExpansion & if not defined DEBUG (echo off)

for /f "skip=4" %%e in ('"echo(prompt $E| "%ComSpec%" /d 2>nul"') do (
    for /f "tokens=4,6 delims=[.] " %%t in ('"ver"') do (
        set "[red]="         & set "[/red]="
        set "[b]="           & set "[/b]="
        set "[u]="           & set "[/u]="
    ) & if "%%~t" geq "10" if "%%~u" geq "10586" (
        set "[red]=%%~e[31m" & set "[/red]=%%~e[39m"
        set "[b]=%%~e[1m"    & set "[/b]=%%~e[22m"
        set "[u]=%%~e[4m"    & set "[/u]=%%~e[24m"
    )
)

::: Prints the given message and the line separator
::: to the "standard" output stream.
@call :define_echo_macro $log

::: Prints the given message and the line separator
::: to the "standard" error output stream.
@call :define_echo_macro $err 2

@goto :main


:define_echo_macro (name: string, stream: number?) > Result
    setlocal EnableExtensions & (if "%~1"=="" (exit /b 2)) & (set \n=^^^
%= This is supposed to be empty! Removing that will cause cryptic errors! =%
)

    ::: Avoid handle duplication during redirection to the `CONOUT$` device
    set "stream=" & if not "%~2"=="" if "%~2" neq "1" (set "stream=^>^&%~2")

    endlocal & set ^"%~1=for %%# in (1 2) do if "%%#" equ "2" (%\n%
        setlocal EnableDelayedExpansion%\n%
        if not "!args!"=="," (%\n%
            for /f "tokens=1,* delims= " %%0 in ("!args!") do (%\n%
                endlocal ^& endlocal ^& (echo(%%~1)%\n%
            )%\n%
        ) else  endlocal ^& endlocal ^& (echo()%\n%
    ) %stream% else setlocal DisableDelayedExpansion ^& set args=, "

    exit /b 0

::: Checks if the file located by this path is a directory.
::: Follows symbolic links in the path.
::: See also: https://learn.microsoft.com/en-gb/windows/win32/fileio/file-attribute-constants
:is_directory (path: string?) > Result
    for /f "tokens=1,* delims=d" %%a in ("-%~a1") do (
        if not "%%b"=="" exit /b 0 "FILE_ATTRIBUTE_DIRECTORY"
    )

    exit /b 1 "File does not exist, is not a directory, or it cannot be determined"

::: Accepts a package name, a path to a Sublime data directory and an optional
::: path to a Sublime package repository, defaulting to the current working
::: directory if not present. If there exists an override for the given package
::: present in the repository, it is removed; otherwise, a junction is installed
::: to the package in the specified directory.
:::
::: Creates a backup of the local Sublime package directory in the process.
:link (sublime_path: string, package: string, cwd: string = ".") > Result
    setlocal & (if "%~1"=="" (exit /b 2)) & (if "%~2"=="" (exit /b 2))

    if not "%~3"=="" (set "cwd=%~3") else (set "cwd=.")
    for /f "delims=" %%p in ("%cwd%") do set "repository=%%~fp"

    ::: According to Package Control, packages are git repositories
    call :is_directory "%repository%\.git" || (
        call :error 1 "'%repository%' is not a Sublime package repository"
    )

    set "package=%~2"

    if /i not "%~f2"=="%repository%\%package%" (
        call :error 1 "'%package%' does not name a package, but is either a path or a glob"
    )

    for /f "delims=" %%r in ("%~f1.") do set "data_root=%%~fr"

    ::: Backup the entire directory first lest something breaks while symlinking
    robocopy "%data_root%\Packages" ^
             "%data_root%\Backup Packages" ^
             /z /xj /mir /dst /sec /im >nul 2>&1

    set "junction=%data_root%\Packages\%package%"

    call :is_directory "%junction%" && (
        rmdir /q "%junction%" 2>nul && (
            %$log% "Removed '%[b]%%package%%[/b]%' package override from '%junction%'."
        ) || (
            call :error 1 "could not unlink the specified directory (OS error: 2)"
        )
    ) || (
        mklink /j "%junction%" "%repository%\%package%" >nul 2>&1 && (
            %$log% "Installed '%[b]%%package%%[/b]%' package override to '%junction%'."
        ) || (
            call :error 1 "could not create directory junction (OS error: 2)"
        )
    )

    endlocal & exit /b 0

::: Lists all local package overrides, if any, in a Sublime data directory
::: specified by the given path.
:list (sublime_path: string) > Result
    setlocal & (if "%~1"=="" (exit /b 2))

    for /f "delims=" %%p in ("%~f1\Packages") do set "package_root=%%~fp"

    set "junctions="

    for /f "delims=" %%d in ('"dir /a:dl /b /o:n "%package_root%" 2>nul"') do (
        if not defined junctions (
            set "junctions=true"

            %$log% "Local package override(s) found:"
            %$log%
        )

        for /f "skip=9 tokens=1,2,*" %%j in ('
            "fsutil reparsepoint query "%package_root%\%%~d""
        ') do (
            if "%%~j"=="Print" if "%%~k"=="Name:" if not "%%~l"=="" (
                %$log% "    %[b]%%%~d:%[/b]% %%~l -> %package_root%\%%~d"
            )
        )
    )

    if not defined junctions (%$log% "No local package overrides found.")

    endlocal & exit /b 0

::: Exits the currently running program with the specified status code (if any).
::: Never returns normally.
:exit (exit_code: number?) > Abort > Nothing
    setlocal

    set "exit_code=%1"

    ::: Without a fully-qualified path, Windows first looks in the application
    ::: directory (`%__APPDIR__%`) and in the current directory (`%__CD__%`) if
    ::: `NeedCurrentDirectoryForExePathW(ExeName)` is true before checking the
    ::: system directories, thus try to avoid executing unqualified `cmd.exe`.
    if not defined ComSpec (set "ComSpec=%SystemRoot%\System32\cmd.exe")

    (goto & goto & call :is_label_context "%%~0") 2>nul && (
        call :exit %exit_code%
    ) || (call :is_label_context :is_label_context) 2>nul && (
        exit /b %exit_code%
    ) || (
        "%ComSpec%" /d /c @exit /b %exit_code%
    ) & if defined CMD_TITLE (
        title %CMD_TITLE%
    ) else (
        title %CD%
    )

    :is_label_context (context: string) > Result
        setlocal & (if "%~1"=="" (exit /b 2))

        set "context=%~1"
        if "%context:~0,1%"==":" (set "exit_code=0") else (set "exit_code=1")

        endlocal & exit /b %exit_code%

    endlocal & exit /b 0xc000013a "The `exit` subroutine never returns normally"

::: Prints the given error message to the "standard" error output stream,
::: then exits the program with the specified (likely unsuccessful) status code.
:error (exit_code: number?, message: string?) > Abort
    setlocal EnableDelayedExpansion

    set "program=%~n0"

    set "message=%~2" & if not "!message: =!"=="" (set "message=: !message!")
    %$err% "%[red]%[%program% error]%[/red]%!message!"

    endlocal & call :exit %1

::: Prints the script's help text to the "standard" output stream,
::: then exits the program with a successful result status code.
:usage () > Abort
    setlocal

    set "program=%~n0"

    %$log% "A simple tool to keep track of locally overridden Sublime syntax packages."
    %$log%
    %$log% "%[b]%%[u]%Usage:%[/u]% %program%%[/b]% [PACKAGE]   Link or unlink the given package"
    %$log% "       %[b]%%program%%[/b]%             List all created package overrides"
    %$log%
    %$log% "%[b]%%[u]%Arguments:%[/b]%%[/u]%"
    %$log% "  [PACKAGE]         Sublime syntax package to install or remove"
    %$log%
    %$log% "%[b]%%[u]%Options:%[/b]%%[/u]%"
    %$log% "  %[b]%/?, -h, --help%[/b]%    Print help"
    %$log%
    %$log% "%[b]%%[u]%Variables:%[/b]%%[/u]%"
    %$log% "  SUBLIME_PATH      Absolute path to a Sublime data directory"
    %$log% "                    (default: '%%APPDATA%%\Sublime Text')"

    endlocal & call :exit 0

@:main
    ::: Default installation - can be overridden via global environment variable
    ::: This doesn't necessarily have to target Sublime Text - Merge is fine too
    if not defined SUBLIME_PATH (set "sublime_path=%APPDATA%\Sublime Text")

    if defined sublime_path (
        call :is_directory "%sublime_path%\Local"
    ) && (
        call :is_directory "%sublime_path%\Installed Packages"
    ) && (
        call :is_directory "%sublime_path%\Packages"
    ) || (
        call :error 1 "SUBLIME_PATH does not point to a Sublime data directory: '%sublime_path%'"
    )

    if not "%~2"=="" (
        call :error 2 "invalid arguments: '%*'"
    ) else if "%~1"=="/?" (
        call :usage
    ) else if "%~1"=="-h" (
        call :usage
    ) else if "%~1"=="--help" (
        call :usage
    ) else if "%~1"=="" (
        call :list "%sublime_path%"
    ) else call :is_directory "%~1" && (
        call :link "%sublime_path%" "%~1" "."
    ) || (
        call :error 1 "'%~1' is neither a directory nor a valid argument"
    )

    exit /b 0
