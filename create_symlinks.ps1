# CS2 Config Symlink Creator
# Run as Administrator OR with Developer Mode enabled in Windows Settings.

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

Write-Host "`nCreating symlinks..." -ForegroundColor Cyan
Write-Host "Source : $source"
Write-Host "Target : $target`n"

foreach ($file in $cfgFiles) {
    $linkPath = Join-Path $target $file.Name

    # Remove existing file or symlink at the target path
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
        Write-Host "  Removed existing: $($file.Name)" -ForegroundColor Yellow
    }

    # Create the symlink
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName -ErrorAction Stop | Out-Null
        Write-Host "  Linked: $($file.Name)" -ForegroundColor Green
    } catch {
        Write-Error "  Failed to link $($file.Name): $_"
        Write-Error "  Make sure you are running as Administrator or have Developer Mode enabled."
    }
}

Write-Host "`nDone. Verifying links:`n"
foreach ($file in $cfgFiles) {
    $linkPath = Join-Path $target $file.Name
    $item = Get-Item $linkPath -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq "SymbolicLink") {
        Write-Host "  [OK] $($file.Name) -> $($item.Target)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($file.Name)" -ForegroundColor Red
    }
}
