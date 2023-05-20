@setlocal EnableDelayedExpansion EnableExtensions & set "CMD=!CMDCMDLINE!" 2>nul
@if /i not "!CMD!"=="!CMD:/=!" (exit /b 0) else @if not defined DEBUG (echo off)
@reg query "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /z >nul 2>&1
@if !ERRORLEVEL! equ 0 (endlocal & set "CMD=1" & set "CMD_ENV=%~0" & goto :main)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::+ doc comment on this
:install_hook
    for /f "usebackq tokens=*" %%i in ('%~dp0.') do set root=%%~fi

    set dependencies=bat cargo git less node onefetch subl yarn zoxide

:::set dependencies=git cargo bat subl powershell onefetch zoxide
:::::: check dependencies
:::
:::echo something about registering this script as an autorun script asdfsgfd
::: verbose
::: i hope i have it in me to clean this up

    endlocal & exit /b 0

:require (arguments, values...)
    setlocal EnableDelayedExpansion

    set /a index=0 >nul 2>&1
    set /a arguments=%~1 || (
        echo(%~0: arguments expects a number, not '%~1'
        exit /b 2
    ) >&2

    :require_loop
        if "%~2"=="" (

            ::: todo finishme aaaaaaaaaaaaaaaaAAAAAAAAAAAAAAAAAAA
        )

    endlocal & exit /b 0

::: rudimentary
::: some function for checking file/directory would be useful here

::: "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Command Processor"
::: key: AutoRun (REG_EXPAND_SZ)
::: (or HKEY_CURRENT_USER)
:::    @if exist "%USERPROFILE%\.cmd" "%USERPROFILE%\.cmd"
::: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/cc771320(v=ws.11)

::: Komputer\HKEY_CLASSES_ROOT\Directory\ContextMenus\PowerShell7x64\shell
::: Komputer\HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShell7x64
::: Komputer\HKEY_CLASSES_ROOT\Directory\shell\PowerShell7x64
::: Komputer\HKEY_CLASSES_ROOT\Drive\shell\PowerShell7x64
::: Komputer\HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\Open with Sublime Text
::: Komputer\HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text

::: Activate Automatic Completion (this is on by default for all recent versions of Windows)
::: [HKEY_LOCAL_MACHINE\Software\Microsoft\Command Processor]
::: "CompletionChar"=0x9

::: [HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\runas]

::: [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system]
::: "verbosestatus"=dword:00000001

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Terminal settings
:::

:main
    setlocal EnableExtensions
    ::%%~E[3;1H
    ::%%~E[1F
    ::: Disable text cursor blinking, then clean up the buffer and return
    for /f "usebackq" %%E in (`echo(prompt $E ^| "%ComSpec%" /d /q 2^>nul`) do (
        set /p="%%~E7%%~E[?12l" & if not defined DEBUG (set /p="%%~E[1F%%~E[0J")
    ) <nul

    ::: If editorconfig file exists, parse and apply its properties (tab width)
    for /f "delims=" %%i in ("%~dp0.") do set editorconfig=%%~fi\.editorconfig
    if exist "%editorconfig%" if not exist "%editorconfig%\*" (
        set editorconfig_root=
        set editorconfig_file_wildcard=
        for /f "usebackq tokens=1,* delims=?!*= " %%i in ("%editorconfig%") do (
            if /i "%%~i"=="root" (
                set editorconfig_root=%%~j
            ) else if defined editorconfig_root (
                if "%%~i"=="[" (
                    if "%%~j"=="]" (
                        set editorconfig_file_wildcard=*
                    ) else (
                        set editorconfig_file_wildcard=
                    )
                ) else if defined editorconfig_file_wildcard (
                    set editorconfig_%%~i=%%~j
                )
            )
        )
    ) >nul 2>&1

    set tabs=%editorconfig_tab_width%

    ::: Expand tabs to n spaces if not defined
    if /i not "%tabs%"=="unset" set /a _=-%tabs% >nul 2>&1 || set /a tabs=4 >nul

    ::: todo explain how this hack works in case some poor soul stumbles upon it
    ::+ Propagate pager settings further, i.e. tab width if not explicitly unset
    endlocal & if /i not "%tabs%"=="unset" (
        if /i "%MORE:/t=%"=="%MORE%" set "MORE=/t%tabs% %MORE%" &rem(%"=="/t=MOREtabsMORE" set MORE=/t%tabs%
    )

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Aliases and metaprogramming
:::

::: jeb's metavariable quote magic: https://stackoverflow.com/a/76213522/6724141
@set i as $*=%%^^^^^^^^ in ("") do @for /f "delims=" %%i in (^^^^""$*%%~^^^^"^")

::: prettify ls (/n does nothing btw, don't bother)
set DIRCMD=/d /o:n /q /r /t:w
::: Use Sublime Test as the editor for commands that prompt for input (e.g. git)
set EDITOR=subl --wait

set HELP=bat --plain --language=cmd-help --nonprintable-notation unicode

set WSL_UTF8=1
::: more
if /i "%MORE:/e=%"=="%MORE%" set "MORE=/e %MORE%" &rem(%"=="/e=MOREMORE" set MORE=/e%

::: Useful one-liners
doskey e = (echo(%%ERRORLEVEL%%)
doskey b = bat $*
doskey m = (doskey /macros)
doskey g = for %i as $*% do @(if "%%~i"=="" (git status) else (git  %%~i))
doskey l = for %i as $*% do @(if "%%~i"=="" (dir -- .)   else (dir  %%~i))
doskey s = for %i as $*% do @(if "%%~i"=="" (subl -- .)  else (subl %%~i))
doskey h = for %i as $*% do @( ^
    if "%%~i"=="" ( ^
        doskey /history ^
    ) else ( ^
        doskey /history $B "%SystemRoot%\System32\findstr.exe" /irc:"%%~i" ^
    ) ^
)

doskey ? = for %i as $*% do @( ^
    if not "%%~i"=="" ( ^
        %%~i --help ^| %HELP% ^
    ) else ( ^
        (echo(Usage: ? ^^^<command^^^> [options]) ^>^&2 ^& (call) ^
    ) ^
)

doskey y = for %i as $*% do @( ^
    if exist ".\yarnw" ( ^
        .\yarnw %%~i ^
    ) else ( ^
        yarn %%~i ^
    ) ^
)

::: Debugging machinery
doskey ' = ( ^
    if not defined DEBUG ( ^
        set "DEBUG=on >nul 2>&1" ^&^& (echo Debugging has been turned ON.) ^
    ) else ( ^
        set "DEBUG="             ^&^& (echo Debugging has been turned OFF.) ^
    ) ^
)

doskey true  = (call )
doskey false = (call)

::: @TODO better descriptions
::: Environment Variables
doskey env = (rundll32 sysdm.cpl,EditEnvironmentVariables)
::: ClearType Text Tuner a.k.a. subpixel rendering
doskey ctt = (cttune)
::: System Information
doskey info = (msinfo32)
::: Control Panel
doskey cpl = (rundll32 shell32.dll,Control_RunDLL)
::: Lock PC
doskey lock = (rundll32 user32.dll,LockWorkStation)

::: set WTTR_LOCATION to your location
::: todo migrate to batch sometime
doskey w = for %i as $*% do @(powershell -ExecutionPolicy "Bypass" -NoProfile -NonInteractive "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; $place = [uri]::EscapeUriString($(If ([string]::IsNullOrWhiteSpace('%%~i')) { "${env:WTTR_LOCATION}" } Else { '%%~i' })); $weather = (Invoke-WebRequest "wttr.in/${place}?mF" -UseBasicParsing -Method 'Get' -UserAgent 'curl').Content; echo `r ${weather}.Replace($([char] 0x2196), $([char] 0x005C)).Replace($([char] 0x2197), $([char] 0x002F)).Replace($([char] 0x2198), $([char] 0x005C)).Replace($([char] 0x2199), $([char] 0x002F)).Replace($([char] 0x26A1).ToString(), $([char] 0x250C).ToString() + $([char] 0x2518).ToString()).Trim();")

set ONEFETCH_HOOKED=1

set ZOXIDE_HOOKED=1
set __ZOXIDE_Z_PREFIX=z

set __ZOXIDE_CD=chdir /d
set __ZOXIDE_PWD=chdir
set __ZOXIDE_HOOK=(for /f "delims=" %%l in ('%__ZOXIDE_PWD%') do @(zoxide add -- "%%~fl\."))

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Path utilities
:::

set OLDPWD=

set BUILTIN_CD=chdir /d
set BUILTIN_PWD=chdir

doskey cd = ( ^
    for %i as $*% do @( ^
        if "%%~i"=="" ( ^
            if defined USERPROFILE ( ^
                if /i not "%%CD%%"=="%%USERPROFILE%%" ( ^
                    %BUILTIN_CD% "%%USERPROFILE%%" ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) else ( ^
                (^>^&2 echo(%~nx0: cd: USERPROFILE is not set) ^& (call) ^
            ) ^
        ) else if "%%~i"=="-" ( ^
            if defined OLDPWD ( ^
                if /i not "%%CD%%"=="%%OLDPWD%%" ( ^
                    %BUILTIN_CD% "%%OLDPWD%%" ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) else ( ^
                (^>^&2 echo(%~nx0: cd: OLDPWD is not set) ^& (call) ^
            ) ^
        ) else ( ^
            if defined CD ( ^
                if /i not "%%CD%%"=="%%~fi" ( ^
                    %BUILTIN_CD% %%~fi ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) else ( ^
                (^>^&2 echo(%~nx0: cd: can't determine current directory) ^& (call) ^
            ) ^
        ) ^
    ) ^
)

doskey cd.. = break

doskey cd/ = break

doskey cd\ = break

::+ todo description and output
doskey file = ( ^
    for %i as $*% do @for /f "tokens=1,2 delims=d" %%a in ("-%%~ai") do @( ^
        if not "%%~b"=="" ( ^
            (echo(Directory) ^& (call ) ^
        ) else if not "%%~a"=="-" ( ^
            (echo(File)      ^& (call ) ^
        ) else ( ^
            (echo(Neither a file nor a directory) ^& (call) ^
        ) ^
    ) ^
)

::+ todo description and output
doskey pwd = ( ^
    for %i as $*% do @if /i not "%%~i"=="/p" (%BUILTIN_PWD%) else ( ^
        ( ^
            for /f "skip=9 tokens=1,2,*" %%j in ('fsutil reparsepoint query .') do @( ^
                if "%%~j"=="Print" if "%%~k"=="Name:" if not "%%~l"=="" (echo(%%~l) ^
            ) ^
        ) $B$B (%BUILTIN_PWD%) ^
    ) ^
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: zoxide
:::

doskey z = ( ^
    for %i as $*% do @( ^
        if "%%~i"=="" ( ^
            if defined HOME ( ^
                if /i not "%%CD%%"=="%%HOME%%" ( ^
                    %BUILTIN_CD% "%%HOME%%" ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) ^
        ) else if "%%~i"=="-" ( ^
            if defined OLDPWD ( ^
                if /i not "%%CD%%"=="%%OLDPWD%%" ( ^
                    %BUILTIN_CD% "%%OLDPWD%%" ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) ^
        ) else ( ^
            for /f "usebackq delims=" %%p in ( ^
                `"zoxide query --exclude "%%CD%%\." -- %%~i"` ^
            ) do @( ^
                if /i not "%%CD%%"=="%%~fp" ( ^
                    %BUILTIN_CD% %%~fp ^
                        ^&^& set "OLDPWD=%%CD%%" ^
                        ^&^& %__ZOXIDE_HOOK% ^
                ) ^
            ) ^
        ) ^
    ) ^
)

doskey zi = ( ^
    for %i as $*% do @for /f "usebackq delims=" %%p in ( ^
        `"zoxide query --interactive -- %%~i"` ^
    ) do @( ^
        if /i not "%%CD%%"=="%%~fp" ( ^
            %BUILTIN_CD% %%~fp ^
                ^&^& set "OLDPWD=%%CD%%" ^
                ^&^& %__ZOXIDE_HOOK% ^
        ) ^
    ) ^
) ^&^& if defined ONEFETCH_HOOKED ( ^
    for /f "delims=" %%r in ('"git rev-parse --show-toplevel 2$Gnul"') do @( ^
        if not "%%~r"=="%%LAST_REPOSITORY%%" ( ^
            onefetch ^
        ) ^& set "LAST_REPOSITORY=%%~r" ^
    ) ^
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::
::: Cleanup
:::

@set i as $*=

@if not defined PROMPT set PROMPT=$P$G
