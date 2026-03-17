# CS2 Config Symlink Creator
# Run as Administrator OR with Developer Mode enabled in Windows Settings.

$source = "F:\GitHub\mynameistito\CS2-Configs"
$target = "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"

# Verify target directory exists
if (-not (Test-Path $target)) {
    Write-Error "Target directory not found: $target"
    Write-Error "Make sure CS2 is installed at the default Steam path."
    exit 1
}

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
