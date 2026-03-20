# CS2-Configs Deployment Script
# Supports CS2, CSGO (legacy), and Counter-Strike: Source
# Symlink mode requires Administrator OR Developer Mode enabled in Windows Settings.

param(
    [string]$Mode = "",   # "symlink" | "copy"
    [string]$Game = ""    # "cs2" | "csgo" | "css" | "all" | comma-separated e.g. "cs2,css"
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ESC      = [char]27

# ---------------------------------------------------------------------------
# Keep window alive when launched via "Run with PowerShell" / GUI shortcut
# ---------------------------------------------------------------------------
# If this is an initial GUI launch (no Mode/Game args, not already relaunched),
# relaunch with -NoExit so the PS prompt stays open after the script finishes.
if (($Mode -eq "" -and $Game -eq "") -and ($env:DEPLOY_STAY_OPEN -ne '1')) {
    $cmdLine = [Environment]::GetCommandLineArgs() -join ' '
    if ($cmdLine -match '-[Ff]ile\b') {
        $env:DEPLOY_STAY_OPEN = '1'
        $pwshExe = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        Start-Process $pwshExe -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        exit 0
    }
}

# ---------------------------------------------------------------------------
# Terminal UI — clack/prompts style
# ---------------------------------------------------------------------------

function Invoke-MultiSelect {
    <#
        Arrow keys  — move focus
        SPACE       — toggle selection
        ENTER       — confirm
        Returns an array of the selected keys (may be empty).
    #>
    param(
        [string]   $Prompt,
        [string[]] $Keys,
        [string[]] $Labels
    )

    $n          = $Keys.Count
    $selected   = New-Object bool[] $n
    $cursor     = 0
    $totalLines = $n + 2   # title line + N option lines + footer line
    $firstDraw  = $true

    Write-Host -NoNewline "${ESC}[?25l"   # hide cursor

    try {
        while ($true) {
            if (-not $firstDraw) {
                # Move cursor back up to the top of the widget
                Write-Host -NoNewline "${ESC}[$($totalLines)A"
            }

            # ── title ────────────────────────────────────────────────────────
            Write-Host "${ESC}[2K${ESC}[96m◆${ESC}[0m  $Prompt"

            # ── options ──────────────────────────────────────────────────────
            for ($i = 0; $i -lt $n; $i++) {
                $focus = ($i -eq $cursor)
                $sel   = $selected[$i]

                $pipe = if ($focus) { "${ESC}[96m│${ESC}[0m" } else { "${ESC}[2m│${ESC}[0m" }
                $dot  = if ($sel)   { "${ESC}[32m●${ESC}[0m" } else { "${ESC}[2m○${ESC}[0m" }
                $lbl  = if ($focus) { "${ESC}[1m$($Labels[$i])${ESC}[0m" } `
                                    else { "${ESC}[2m$($Labels[$i])${ESC}[0m" }

                Write-Host "${ESC}[2K$pipe  $dot  $lbl"
            }

            # ── footer hint ──────────────────────────────────────────────────
            Write-Host "${ESC}[2K${ESC}[96m└${ESC}[0m  ${ESC}[2mSPACE to select  ·  ↑↓ navigate  ·  ENTER confirm${ESC}[0m"

            $firstDraw = $false

            # ── key handling ─────────────────────────────────────────────────
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)   { if ($cursor -gt 0)      { $cursor-- } }
                ([ConsoleKey]::DownArrow) { if ($cursor -lt $n - 1) { $cursor++ } }
                ([ConsoleKey]::Spacebar)  { $selected[$cursor] = -not $selected[$cursor] }
                ([ConsoleKey]::Enter)     { break }
            }

            if ($key.Key -eq [ConsoleKey]::Enter) { break }
        }
    } finally {
        Write-Host -NoNewline "${ESC}[?25h"   # restore cursor
    }

    # ── collapse widget to a 2-line summary ──────────────────────────────────
    $selLabels = for ($i = 0; $i -lt $n; $i++) { if ($selected[$i]) { $Labels[$i] } }
    $summary   = if ($selLabels) { $selLabels -join "  ${ESC}[2m·${ESC}[0m  " } else { "${ESC}[33mnone${ESC}[0m" }

    Write-Host -NoNewline "${ESC}[$($totalLines)A"
    Write-Host "${ESC}[2K${ESC}[32m◇${ESC}[0m  $Prompt"
    Write-Host "${ESC}[2K${ESC}[96m│${ESC}[0m  ${ESC}[2m$summary${ESC}[0m"
    Write-Host -NoNewline "${ESC}[J"   # erase remaining widget lines

    # Return selected keys as an array (leading comma keeps it as array in PS)
    $result = @(for ($i = 0; $i -lt $n; $i++) { if ($selected[$i]) { $Keys[$i] } })
    return ,$result
}

function Invoke-Select {
    <#
        Arrow keys  — move focus
        ENTER       — confirm
        Returns the key string of the chosen option.
    #>
    param(
        [string]   $Prompt,
        [string[]] $Keys,
        [string[]] $Labels
    )

    $n          = $Keys.Count
    $cursor     = 0
    $totalLines = $n + 2
    $firstDraw  = $true

    Write-Host -NoNewline "${ESC}[?25l"

    try {
        while ($true) {
            if (-not $firstDraw) {
                Write-Host -NoNewline "${ESC}[$($totalLines)A"
            }

            Write-Host "${ESC}[2K${ESC}[96m◆${ESC}[0m  $Prompt"

            for ($i = 0; $i -lt $n; $i++) {
                $focus = ($i -eq $cursor)

                $pipe = if ($focus) { "${ESC}[96m│${ESC}[0m" } else { "${ESC}[2m│${ESC}[0m" }
                $dot  = if ($focus) { "${ESC}[96m◉${ESC}[0m" } else { "${ESC}[2m○${ESC}[0m" }
                $lbl  = if ($focus) { "${ESC}[1m$($Labels[$i])${ESC}[0m" } `
                                    else { "${ESC}[2m$($Labels[$i])${ESC}[0m" }

                Write-Host "${ESC}[2K$pipe  $dot  $lbl"
            }

            Write-Host "${ESC}[2K${ESC}[96m└${ESC}[0m  ${ESC}[2m↑↓ navigate  ·  ENTER confirm${ESC}[0m"

            $firstDraw = $false

            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)   { if ($cursor -gt 0)      { $cursor-- } }
                ([ConsoleKey]::DownArrow) { if ($cursor -lt $n - 1) { $cursor++ } }
                ([ConsoleKey]::Enter)     { break }
            }

            if ($key.Key -eq [ConsoleKey]::Enter) { break }
        }
    } finally {
        Write-Host -NoNewline "${ESC}[?25h"
    }

    # Collapse to summary
    Write-Host -NoNewline "${ESC}[$($totalLines)A"
    Write-Host "${ESC}[2K${ESC}[32m◇${ESC}[0m  $Prompt"
    Write-Host "${ESC}[2K${ESC}[96m│${ESC}[0m  ${ESC}[2m$($Labels[$cursor])${ESC}[0m"
    Write-Host -NoNewline "${ESC}[J"

    return $Keys[$cursor]
}

# ---------------------------------------------------------------------------
# Steam Library Discovery
# ---------------------------------------------------------------------------

function Get-SteamLibraryRoots {
    $roots = @()

    $steamRegPath = "HKCU:\Software\Valve\Steam"
    $steamPath    = $null
    try {
        $steamPath = (Get-ItemProperty -Path $steamRegPath -ErrorAction Stop).SteamPath
        $steamPath = $steamPath -replace '/', '\'
    } catch { }

    if ($steamPath -and (Test-Path $steamPath)) {
        $roots += $steamPath

        $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $vdfPath) {
            Get-Content $vdfPath | ForEach-Object {
                if ($_ -match '"path"\s+"([^"]+)"') {
                    $roots += $Matches[1] -replace '\\\\', '\'
                }
            }
        }
    }

    $roots += "C:\Program Files (x86)\Steam"   # classic fallback
    return $roots
}

# ---------------------------------------------------------------------------
# Per-Game Path Finders
# ---------------------------------------------------------------------------

function Find-CS2CfgPath {
    $relative = "steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
    foreach ($root in (Get-SteamLibraryRoots)) {
        $candidate = Join-Path $root $relative
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Find-CSGOCfgPath {
    $candidates = @(
        "steamapps\common\csgo legacy\csgo\cfg",
        "steamapps\common\Counter-Strike Global Offensive\csgo\cfg"
    )
    foreach ($root in (Get-SteamLibraryRoots)) {
        foreach ($relative in $candidates) {
            $candidate = Join-Path $root $relative
            if (Test-Path $candidate) { return $candidate }
        }
    }
    return $null
}

function Find-CSSCfgPath {
    $relative = "steamapps\common\Counter-Strike Source\cstrike\cfg"
    foreach ($root in (Get-SteamLibraryRoots)) {
        $candidate = Join-Path $root $relative
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Resolve $selectedGames
# ---------------------------------------------------------------------------

$validKeys = @("cs2", "csgo", "css")

if ($Game -ne "" -and $Game -ne "all") {
    # Parse comma-separated values passed via CLI or elevated relaunch
    $parsed = $Game -split "," | ForEach-Object { $_.Trim().ToLower() }
    foreach ($g in $parsed) {
        if ($g -notin $validKeys) {
            Write-Error "Invalid game: '$g'. Valid options: cs2, csgo, css, all"
            exit 1
        }
    }
    $selectedGames = @($parsed)
} elseif ($Game -eq "all") {
    $selectedGames = $validKeys
} else {
    # Interactive multi-select
    Write-Host ""
    $selectedGames = Invoke-MultiSelect `
        -Prompt "Which game(s) do you want to deploy configs for?" `
        -Keys   @("cs2",                    "csgo",                                        "css") `
        -Labels @("CS2  (Counter-Strike 2)", "CSGO (Counter-Strike: Global Offensive - legacy)", "CSS  (Counter-Strike: Source)")

    if ($selectedGames.Count -eq 0) {
        Write-Host ""
        Write-Host "${ESC}[33m  No games selected. Exiting.${ESC}[0m"
        Write-Host ""
        exit 0
    }
}

# ---------------------------------------------------------------------------
# Resolve $Mode
# ---------------------------------------------------------------------------

if ($Mode -notin @("symlink", "copy")) {
    Write-Host ""
    $Mode = Invoke-Select `
        -Prompt "How would you like to deploy the configs?" `
        -Keys   @("symlink",                                                                      "copy") `
        -Labels @("Symlink  (requires Admin or Developer Mode — repo changes apply instantly)", "Copy     (no elevation needed — re-run after each git pull)")
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Elevation (symlink mode only)
# ---------------------------------------------------------------------------

if ($Mode -eq "symlink") {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "  ${ESC}[33m⚠  Symlink mode requires elevation. Relaunching as Administrator...${ESC}[0m"
        Write-Host ""
        $scriptPath  = $MyInvocation.MyCommand.Path
        $gameArg     = $selectedGames -join ","
        $pwshExe = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        try {
            Start-Process $pwshExe `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode symlink -Game `"$gameArg`"" `
                -Verb RunAs -ErrorAction Stop
        } catch {
            Write-Host "  ${ESC}[31m✘  UAC was cancelled or elevation failed.${ESC}[0m"
            Write-Host ""
        }
        return
    }
}

# ---------------------------------------------------------------------------
# Game metadata
# ---------------------------------------------------------------------------

$gameMap = @{
    "cs2"  = @{ Label = "CS2  (Counter-Strike 2)";                         FindPath = { Find-CS2CfgPath }  }
    "csgo" = @{ Label = "CSGO (Counter-Strike: Global Offensive - legacy)"; FindPath = { Find-CSGOCfgPath } }
    "css"  = @{ Label = "CSS  (Counter-Strike: Source)";                    FindPath = { Find-CSSCfgPath }  }
}

# ---------------------------------------------------------------------------
# Deploy
# ---------------------------------------------------------------------------

Write-Host "  ${ESC}[2mMode : $Mode${ESC}[0m"
Write-Host "  ${ESC}[2mGame : $($selectedGames -join ', ')${ESC}[0m"
Write-Host ""

$summary = @()

foreach ($gameKey in $selectedGames) {
    $info      = $gameMap[$gameKey]
    $label     = $info.Label
    $sourceDir = Join-Path $repoRoot $gameKey

    Write-Host "${ESC}[96m┌─${ESC}[0m  ${ESC}[1m$label${ESC}[0m"

    # Check source dir for cfg files
    $cfgFiles = @()
    if (Test-Path $sourceDir) {
        $cfgFiles = @(Get-ChildItem -Path $sourceDir -Filter "*.cfg")
    }

    if ($cfgFiles.Count -eq 0) {
        Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[33m⚠  No .cfg files found in .\$gameKey\ — skipping.${ESC}[0m"
        Write-Host "${ESC}[96m└${ESC}[0m"
        Write-Host ""
        $summary += [PSCustomObject]@{ Game = $label; Status = "SKIPPED (no configs)"; Pass = 0; Fail = 0 }
        continue
    }

    $targetDir = & $info.FindPath

    if (-not $targetDir) {
        Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[33m⚠  Game not found / not installed — skipping.${ESC}[0m"
        Write-Host "${ESC}[96m└${ESC}[0m"
        Write-Host ""
        $summary += [PSCustomObject]@{ Game = $label; Status = "SKIPPED (not installed)"; Pass = 0; Fail = 0 }
        continue
    }

    Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[2msource : .\$gameKey\${ESC}[0m"
    Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[2mtarget : $targetDir${ESC}[0m"
    Write-Host "${ESC}[96m│${ESC}[0m"

    $pass = 0
    $fail = 0

    foreach ($file in $cfgFiles) {
        $linkPath = Join-Path $targetDir $file.Name

        if (Test-Path $linkPath) {
            $existing = Get-Item $linkPath -Force
            if ($existing.LinkType -eq "SymbolicLink") {
                Remove-Item $linkPath -Force
            } else {
                $backupPath = "$linkPath.backup"
                if (Test-Path $backupPath) { Remove-Item $backupPath -Force }
                Rename-Item -Path $linkPath -NewName "$($file.Name).backup" -Force
                Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[33m⚠${ESC}[0m  backed up $($file.Name) → $($file.Name).backup"
            }
        }

        if ($Mode -eq "copy") {
            try {
                Copy-Item -Path $file.FullName -Destination $linkPath -ErrorAction Stop
                Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[32m✔${ESC}[0m  copied   $($file.Name)"
            } catch {
                Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[31m✘${ESC}[0m  failed   $($file.Name)  $_"
                $fail++
                continue
            }
        } else {
            try {
                New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName -ErrorAction Stop | Out-Null
                Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[32m✔${ESC}[0m  linked   $($file.Name)"
            } catch {
                Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[31m✘${ESC}[0m  failed   $($file.Name)  (run as Admin or enable Developer Mode)"
                $fail++
                continue
            }
        }

        # Verify immediately after deploy
        $item = Get-Item $linkPath -ErrorAction SilentlyContinue
        $ok   = $item -and (
            ($Mode -eq "symlink" -and $item.LinkType -eq "SymbolicLink") -or
            ($Mode -eq "copy"    -and $item.LinkType -ne "SymbolicLink")
        )
        if ($ok) { $pass++ } else { $fail++ }
    }

    $statusColor = if ($fail -eq 0) { "32" } else { "31" }
    Write-Host "${ESC}[96m│${ESC}[0m"
    Write-Host "${ESC}[96m└${ESC}[0m  ${ESC}[${statusColor}m$pass passed${ESC}[0m  ${ESC}[2m/ $($cfgFiles.Count) total${ESC}[0m"
    Write-Host ""

    $status = if ($fail -eq 0) { "OK" } else { "PARTIAL ($fail failed)" }
    $summary += [PSCustomObject]@{ Game = $label; Status = $status; Pass = $pass; Fail = $fail }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host "${ESC}[96m◆${ESC}[0m  ${ESC}[1mSummary${ESC}[0m"
foreach ($row in $summary) {
    $color = switch -Wildcard ($row.Status) {
        "OK"       { "32" }
        "SKIPPED*" { "33" }
        default    { "31" }
    }
    Write-Host "${ESC}[96m│${ESC}[0m  ${ESC}[${color}m$(if ($row.Status -eq 'OK') {'✔'} elseif ($row.Status -like 'SKIPPED*') {'–'} else {'✘'})${ESC}[0m  $($row.Game)  ${ESC}[2m$($row.Status)${ESC}[0m"
}
Write-Host "${ESC}[96m└${ESC}[0m"
Write-Host ""
Read-Host "Press Enter to close"
