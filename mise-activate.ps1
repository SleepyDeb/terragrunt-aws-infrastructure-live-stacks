# --- Mise PowerShell Integration ---
#
# This script provides integration for the `mise` tool in PowerShell.
#
# Corrections:
# 1. Replaced the hardcoded `mise.exe` path with a dynamic lookup using `Get-Command`.
#    This makes the script portable across different machines and installations.
# 2. Added version checks (`$PSVersionTable.PSVersion.Major -ge 7`) to ensure that
#    modern event handler features (like `LocationChangedAction` and `CommandNotFoundAction`)
#    are only used in PowerShell 7 and newer. This prevents errors in Windows PowerShell 5.1.

# --- Configuration ---
# Find the mise executable dynamically instead of using a hardcoded path.
try {
    $Global:MISE_EXE_PATH = (Get-Command mise.exe -ErrorAction Stop).Source
}
catch {
    Write-Error "mise.exe not found in your PATH. Please ensure mise is installed and accessible."
    return
}

$env:MISE_SHELL = 'pwsh'
$env:__MISE_ORIG_PATH = $env:PATH

# --- Main `mise` function ---
function Global:mise {
    # Read line directly from input to workaround PowerShell input parsing for functions
    $code = [System.Management.Automation.Language.Parser]::ParseInput($MyInvocation.Statement.Substring($MyInvocation.OffsetInLine - 1), [ref]$null, [ref]$null)
    $myLine = $code.Find({ $args[0].CommandElements }, $true).CommandElements | ForEach-Object { $_.ToString() } | Join-String -Separator ' '
    $command, [array]$arguments = Invoke-Expression ('Write-Output -- ' + $myLine)
    
    if ($null -eq $arguments) {
        & $Global:MISE_EXE_PATH
        return
    }

    $command = $arguments[0]
    $arguments = $arguments[1..$arguments.Length]

    if ($arguments -contains '--help') {
        return & $Global:MISE_EXE_PATH $command $arguments
    }

    switch ($command) {
        { $_ -in 'deactivate', 'shell', 'sh', 'activate' } {
            if ($arguments -contains '-h' -or $arguments -contains '--help') {
                & $Global:MISE_EXE_PATH $command $arguments
            }
            else {
                # Execute mise and capture its output to run as commands (e.g., setting environment variables)
                & $Global:MISE_EXE_PATH $command $arguments | Out-String | Invoke-Expression -ErrorAction SilentlyContinue
            }
        }
        default {
            & $Global:MISE_EXE_PATH $command $arguments
            $status = $LASTEXITCODE
            if (Test-Path -Path Function:\_mise_hook) {
                _mise_hook
            }
            # Pass down exit code from mise after _mise_hook
            if ($status -ne 0) {
                exit $status
            }
        }
    }
}

# --- Hook function to update the environment ---
function Global:_mise_hook {
    if ($env:MISE_SHELL -eq "pwsh") {
        & $Global:MISE_EXE_PATH hook-env $args -s pwsh | Out-String | Invoke-Expression -ErrorAction SilentlyContinue
    }
}

# --- Automatic activation on directory change (chpwd) ---
function Global:__enable_mise_chpwd {
    # This feature requires PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if (-not $Global:__mise_pwsh_chpwd) {
            $Global:__mise_pwsh_chpwd = $true
            $_mise_chpwd_hook = [EventHandler[System.Management.Automation.LocationChangedEventArgs]] {
                param([object] $source, [System.Management.Automation.LocationChangedEventArgs] $eventArgs)
                end {
                    _mise_hook
                }
            };
            
            $existingAction = $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction
            if ($existingAction) {
                $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = [Delegate]::Combine($existingAction, $_mise_chpwd_hook)
            }
            else {
                $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = $_mise_chpwd_hook
            }
        }
    } else {
        # Silently skip for older PowerShell versions
    }
}
__enable_mise_chpwd
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_chpwd

# --- Prompt hook for environment updates ---
function Global:__enable_mise_prompt {
    if (-not $Global:__mise_pwsh_previous_prompt_function) {
        $Global:__mise_pwsh_previous_prompt_function = $function:prompt
        function global:prompt {
            if (Test-Path -Path Function:\_mise_hook) {
                _mise_hook
            }
            # Execute the original prompt function
            & $__mise_pwsh_previous_prompt_function
        }
    }
}
__enable_mise_prompt
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_prompt

# --- Initial hook execution ---
_mise_hook

# --- Command Not Found hook for auto-installation ---
if (-not $Global:__mise_pwsh_command_not_found) {
    $Global:__mise_pwsh_command_not_found = $true
    function __enable_mise_command_not_found {
        # This feature requires PowerShell 7+
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $_mise_pwsh_cmd_not_found_hook = [EventHandler[System.Management.Automation.CommandLookupEventArgs]] {
                param([object] $sender, [System.Management.Automation.CommandLookupEventArgs] $eventArgs)
                end {
                    # Check if the command not found is the one the user actually typed
                    if ($eventArgs.CommandName -eq (Get-History -Count 1).CommandLine) {
                        # Ask mise to handle the not-found command
                        if (& $Global:MISE_EXE_PATH hook-not-found -s pwsh -- $eventArgs.CommandName) {
                            _mise_hook
                            # If the command now exists, execute it
                            $newCmd = Get-Command $eventArgs.CommandName -ErrorAction SilentlyContinue
                            if ($newCmd) {
                                $eventArgs.Command = $newCmd
                                $eventArgs.StopSearch = $true
                            }
                        }
                    }
                }
            }
            
            $existingAction = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
            if ($existingAction) {
                $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = [Delegate]::Combine($existingAction, $_mise_pwsh_cmd_not_found_hook)
            }
            else {
                $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $_mise_pwsh_cmd_not_found_hook
            }
        } else {
            # Silently skip for older PowerShell versions
        }
    }
    __enable_mise_command_not_found
    Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_command_not_found
}
