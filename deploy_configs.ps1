# CS2 Config Setup
# Symlink mode requires Administrator OR Developer Mode enabled in Windows Settings.

param(
    [string]$Mode = ""
)

$source = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Auto-detect CS2 cfg directory ---
function Find-CS2CfgPath {
    $cs2Relative = "steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"

    # 1. Read Steam install path from registry
    $steamRegPath = "HKCU:\Software\Valve\Steam"
    $steamPath = $null
    try {
        $steamPath = (Get-ItemProperty -Path $steamRegPath -ErrorAction Stop).SteamPath
        # Registry stores forward slashes on some installs
        $steamPath = $steamPath -replace '/', '\'
    } catch {
        # Registry key not found, will fall through to manual check
    }

    # Collect all library folders to search
    $libraryRoots = @()

    if ($steamPath -and (Test-Path $steamPath)) {
        $libraryRoots += $steamPath

        # Parse libraryfolders.vdf for additional Steam libraries on other drives
        $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $vdfPath) {
            Get-Content $vdfPath | ForEach-Object {
                if ($_ -match '"path"\s+"([^"]+)"') {
                    $libraryRoots += $Matches[1] -replace '\\\\', '\'
                }
            }
        }
    }

    # Also try the classic default path as a last resort
    $libraryRoots += "C:\Program Files (x86)\Steam"

    foreach ($root in $libraryRoots) {
        $candidate = Join-Path $root $cs2Relative
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

$target = Find-CS2CfgPath

if (-not $target) {
    Write-Error "Could not find the CS2 cfg directory automatically."
    Write-Error "Make sure CS2 is installed and has been run at least once."
    exit 1
}

Write-Host "CS2 cfg path detected: $target" -ForegroundColor DarkGray

# Get all .cfg files in the repo
$cfgFiles = Get-ChildItem -Path $source -Filter "*.cfg"

if ($cfgFiles.Count -eq 0) {
    Write-Warning "No .cfg files found in $source"
    exit 1
}

# --- Ask user for mode (skip if already passed in via -Mode) ---
if ($Mode -eq "symlink" -or $Mode -eq "copy") {
    $mode = $Mode
} else {
    Write-Host ""
    Write-Host "How would you like to deploy the configs?" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Symlink  (requires Admin or Developer Mode; changes in repo apply instantly)"
    Write-Host "  [2] Copy     (plain file copy; re-run this script to update)"
    Write-Host ""
    Write-Host "  WARNING: Symlink mode links CS2 configs directly into this repo folder." -ForegroundColor Red
    Write-Host "  If you move, rename, or delete the repo, the symlinks will break" -ForegroundColor Red
    Write-Host "  and your configs will stop loading. Keep this folder in a stable location." -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Enter 1 or 2"
    $mode = if ($choice -eq "2") { "copy" } else { "symlink" }
}

if ($mode -eq "symlink") {
    # Auto-elevate to Administrator if not already running elevated
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "Symlink mode requires elevation. Relaunching as Administrator..." -ForegroundColor Yellow
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode symlink" -Verb RunAs
        exit
    }
}

Write-Host ""
Write-Host "Mode   : $mode" -ForegroundColor Cyan
Write-Host "Source : $source"
Write-Host "Target : $target`n"

foreach ($file in $cfgFiles) {
    $linkPath = Join-Path $target $file.Name

    # Remove existing file or symlink at the target path
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
        Write-Host "  Removed existing: $($file.Name)" -ForegroundColor Yellow
    }

    if ($mode -eq "copy") {
        try {
            Copy-Item -Path $file.FullName -Destination $linkPath -ErrorAction Stop
            Write-Host "  Copied: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Error "  Failed to copy $($file.Name): $_"
        }
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName -ErrorAction Stop | Out-Null
            Write-Host "  Linked: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Error "  Failed to link $($file.Name): $_"
            Write-Error "  Make sure you are running as Administrator or have Developer Mode enabled."
        }
    }
}

Write-Host "`nDone. Verifying files:`n"
foreach ($file in $cfgFiles) {
    $linkPath = Join-Path $target $file.Name
    $item = Get-Item $linkPath -ErrorAction SilentlyContinue
    if ($item) {
        if ($mode -eq "symlink" -and $item.LinkType -eq "SymbolicLink") {
            Write-Host "  [OK] $($file.Name) -> $($item.Target)" -ForegroundColor Green
        } elseif ($mode -eq "copy" -and $item.LinkType -ne "SymbolicLink") {
            Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $($file.Name)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] $($file.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Press Enter to close"
