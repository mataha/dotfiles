::: sublink
::: =======
:::
::: A simple tool to keep track of locally overridden Sublime syntax packages.
:::
::: Usage: link             List all created package overrides
:::        link [PACKAGE]   Link or unlink the given package
:::
::: Arguments:
:::   [PACKAGE]             Sublime syntax package to install or remove
:::
::: Options:
:::   /?, -h, --help        Print help
:::
::: Variables:
:::   SUBLIME_PATH          Absolute path to a Sublime data directory
:::                         (default: '%APPDATA%\Sublime Text')
:::

@setlocal DisableDelayedExpansion & if not defined DEBUG echo off

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Macros
:::

(set \n=^^^
%= This is supposed to be empty! Removing this will result in cryptic errors! =%
)

::+ Returns a successful result.
::+ Always succeeds.
set ^"$true=(call )"

::+ Prints the given message and the line separator
::+ to the "standard" output stream.
set ^"$log=for %%# in (1 2) do if "%%#" equ "2" (                           %\n%
    setlocal EnableDelayedExpansion                                         %\n%
    if not "!args!"=="," (                                                  %\n%
        for /f "tokens=1,* delims= " %%0 in ("!args!") do (                 %\n%
            endlocal ^& endlocal                                            %\n%
            (echo(%%~1)                                                     %\n%
        )                                                                   %\n%
    ) else (endlocal ^& endlocal ^& (echo())                                %\n%
) else setlocal DisableDelayedExpansion ^& set args=, "

::+ Prints the given message and the line separator
::+ to the "standard" error output stream.
set ^"$err=for %%# in (1 2) do if "%%#" equ "2" (                           %\n%
    setlocal EnableDelayedExpansion                                         %\n%
    if not "!args!"=="," (                                                  %\n%
        for /f "tokens=1,* delims= " %%0 in ("!args!") do (                 %\n%
            endlocal ^& endlocal                                            %\n%
            (echo(%%~1)                                                     %\n%
        )                                                                   %\n%
    ) else (endlocal ^& endlocal ^& (echo())                                %\n%
) ^>^&2 else setlocal DisableDelayedExpansion ^& set args=, "

(set \n=)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Markup
:::

for /f %%e in ('"echo(prompt $E| "%ComSpec%" /d 2>nul"') do (
    for /f "tokens=4,6 delims=[.] " %%t in ('"ver"') do (
        set "[red]="         & set "[/red]="
        set "[b]="           & set "[/b]="
        set "[u]="           & set "[/u]="
    ) & if "%%~t" geq "10"   if "%%~u" geq "10586" (
        set "[red]=%%~e[31m" & set "[/red]=%%~e[39m"
        set "[b]=%%~e[1m"    & set "[/b]=%%~e[22m"
        set "[u]=%%~e[4m"    & set "[/u]=%%~e[24m"
    )
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: The program itself
:::

@goto :main


::+ Checks if the file located by this path is a directory.
::+ Follows symbolic links in the path.
::+ See also: https://learn.microsoft.com/en-gb/windows/win32/fileio/file-attribute-constants
:is_directory (path: string?) -> Result
    for /f "tokens=1,* delims=d" %%a in ("-%~a1") do (
        if not "%%b"=="" exit /b 0 "FILE_ATTRIBUTE_DIRECTORY"
    )

    exit /b 1 "File does not exist, is not a directory, or it cannot be determined"

::+ Accepts a package name, a path to a Sublime data directory and an optional
::+ path to the Sublime Packages repository, defaulting to the current working
::+ directory if not present. If there exists an override for the given package
::+ present in the repository it is removed; otherwise, installs a junction
::+ to the package in the specified directory, creating a backup in the process.
:link (sublime_path: string, package: string, cwd: string = ".") -> Result
    setlocal & (if "%~1"=="" (exit /b 2)) & (if "%~2"=="" (exit /b 2))

    if not "%~3"=="" (set "cwd=%~3") else (set "cwd=.")
    for /f "delims=" %%p in ("%cwd%") do set "repository=%%~fp"

    ::: You lye, you are not sure; for I say, Woman, 'tis impossible to be sure
    ::: of any thing but Death and Taxes and Lorem Ipsum ~ Toby Guzzle, 1716
    call :is_directory "%repository%\Text\Snippets" && %$true% || (
        call :die 1 "not a Sublime Packages repository: '%repository%'"
    )

    set "package=%~2"

    if /i not "%~f2"=="%repository%\%package%" (
        call :die 1 "'%package%' does not name a package, but is either a path or a glob"
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
            call :die 1 "could not unlink the specified directory (OS error: 2)"
        )
    ) || (
        mklink /j "%junction%" "%repository%\%package%" >nul 2>&1 && (
            %$log% "Installed '%[b]%%package%%[/b]%' package override to '%junction%'."
        ) || (
            call :die 1 "could not create directory junction (OS error: 2)"
        )
    )

    endlocal & exit /b 0

::+ Lists all local package overrides, if any, in the Sublime data directory
::+ specified by the given path.
:list (sublime_path: string) -> Result
    setlocal & (if "%~1"=="" (exit /b 2))

    for /f "delims=" %%p in ("%~f1\Packages") do set "package_root=%%~fp"

    set "junctions="

    for /f "delims=" %%d in ('"dir /a:dl /b /o:n "%package_root%" 2>nul"') do (
        if not defined junctions (
            set "junctions=true"

            %$log% "Local package override(s) found:"
            %$log%
        )

        %$log% "    %[b]%%%~d:%[/b]% %package_root%\%%~d"
    )

    if not defined junctions (%$log% "No local package overrides found.")

    endlocal & exit /b 0

::+ Prints the given error message to the "standard" error output stream,
::+ then terminates the program with the specified status code.
:die (exit_code: number, message: string?) -> Result
    set "program=%~n0"

    %$err% "%[red]%[%program% error]%[/red]%: %~2"

    (goto) 2>nul & exit /b %1

::+ Prints the script's help text to the "standard" output stream,
::+ then terminates the program with a successful result status code.
:usage () -> Result
    set "program=%~n0"

    %$log% "A simple tool to keep track of locally overridden Sublime syntax packages."
    %$log%
    %$log% "%[b]%%[u]%Usage:%[/u]% %program%%[/b]%             List all created package overrides"
    %$log% "       %[b]%%program%%[/b]% [PACKAGE]   Link or unlink the given package"
    %$log%
    %$log% "%[b]%%[u]%Arguments:%[/b]%%[/u]%"
    %$log% "  [PACKAGE]         Sublime syntax package to install or remove"
    %$log%
    %$log% "%[b]%%[u]%Options:%[/b]%%[/u]%"
    %$log% "  %[b]%/?, -h, --help%[/b]%    Print help"
    %$log%
    %$log% "%[b]%%[u]%Variables:%[/b]%%[/u]%"
    %$log% "  %[b]%SUBLIME_PATH%[/b]%      Absolute path to a Sublime data directory"
    %$log% "                    (default: '%%APPDATA%%\Sublime Text')"

    (goto) 2>nul & exit /b 0

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
        call :die 1 "SUBLIME_PATH does not point to a Sublime data directory: '%sublime_path%'"
    )

    if not "%~2"=="" (
        call :die 2 "invalid arguments: '%*'"
    ) else if "%~1"=="/?" (
        call :usage
    ) else if "%~1"=="-h" (
        call :usage
    ) else if "%~1"=="--help" (
        call :usage
    ) else if "%~1"=="" (
        call :list "%sublime_path%"
    ) else call :is_directory "%~1" & if ERRORLEVEL 1 (
        call :die 1 "'%~1' is neither a directory nor a valid argument"
    ) else (
        call :link "%sublime_path%" "%~1" "."
    )

    exit /b
