# CS2 Configs — mynameistito

Personal Counter-Strike 2 configuration files. Includes binds, convars, crosshair, aliases, and a surf-specific bind profile — all managed via Git and symlinked into the CS2 cfg directory.

**Steam:** [steamcommunity.com/id/mynameistito](https://steamcommunity.com/id/mynameistito/)

---

## Launch Options

```
-novid -allow_third_party_software +exec autoexec.cfg
```

| Flag | Purpose |
|---|---|
| `-novid` | Skip the Valve intro video on launch |
| `-allow_third_party_software` | Required for some external tools and overlays |
| `+exec autoexec.cfg` | Force-execute autoexec on every game launch |

---

## File Structure

```
CS2-Configs/
├── autoexec.cfg              # Entry point — execs all other configs
├── config_aliases.cfg        # Custom aliases and server shortcuts
├── config_convars.cfg        # All game settings and convars
├── config_crosshair.cfg      # Crosshair settings
├── config_default_binds.cfg  # Standard competitive/DM binds
├── config_surf_binds.cfg     # Surf-specific binds (swaps in/out automatically)
├── config_allkeys.cfg        # Diagnostic — binds every key to echo its name or "KEY NOT BOUND"
└── deploy_configs.ps1        # PowerShell script to deploy configs into CS2 (symlink or copy)
```

### autoexec.cfg

The entry point. Executed on every game launch via the launch option. Loads all other configs in order:

```
exec config_aliases.cfg
exec config_convars.cfg
exec config_default_binds.cfg
exec config_crosshair.cfg
```

---

## Settings

### Mouse & Sensitivity

| Convar | Value |
|---|---|
| `sensitivity` | `1.25` |
| `m_pitch` | `0.022` |
| `m_yaw` | `0.022` |
| `mouse_inverty` | `false` |

### View & FOV

| Convar | Value |
|---|---|
| `fov_desired` | `75` |
| `viewmodel_fov` | `68` |
| `viewmodel_offset_x` | `2.5` |
| `viewmodel_offset_y` | `2` |
| `viewmodel_offset_z` | `-2` |
| `viewmodel_presetpos` | `1` |

### HUD

| Convar | Value |
|---|---|
| `hud_scaling` | `0.9` |
| `cl_radar_scale` | `0.25` |
| `cl_radar_always_centered` | `false` |
| `cl_radar_icon_scale_min` | `0.6` |
| `cl_hud_radar_scale` | `1` |

### Sound

Most ambient sounds are muted for a clean, focused audio experience.

| Convar | Value |
|---|---|
| `snd_menumusic_volume` | `0` |
| `snd_mvp_volume` | `0` |
| `snd_roundstart_volume` | `0` |
| `snd_roundend_volume` | `0` |
| `snd_roundaction_volume` | `0` |
| `snd_tensecondwarning_volume` | `0` |
| `snd_deathcamera_volume` | `0` |

---

## Crosshair

Small, static white crosshair. No dot, no recoil movement, no T-style.

| Convar | Value |
|---|---|
| `cl_crosshairstyle` | `4` (static) |
| `cl_crosshaircolor` | `4` (custom) |
| `cl_crosshaircolor_r/g/b` | `255 / 255 / 255` (white) |
| `cl_crosshairalpha` | `255` |
| `cl_crosshairsize` | `1` |
| `cl_crosshairthickness` | `1` |
| `cl_crosshairgap` | `-4` |
| `cl_crosshairdot` | `0` |
| `cl_crosshair_recoil` | `0` |
| `cl_crosshair_drawoutline` | `0` |
| `cl_crosshair_t` | `0` |
| `cl_crosshairgap_useweaponvalue` | `0` |

---

## Key Binds

Binds use **scancodes** instead of key names, making them layout-independent (works on QWERTY, AZERTY, etc.).

### config_default_binds.cfg — Competitive / DM

| Key | Action |
|---|---|
| `W / A / S / D` | Move Forward / Left / Back / Right |
| `SPACE` | Jump (also B-Hop on scroll wheel up/down) |
| `SHIFT` | Crouch |
| `CTRL` | Walk / Sprint |
| `MOUSE1` | Fire |
| `MOUSE2` | Alt Fire / Scope |
| `MOUSE3` | Ping Location |
| `MOUSE4` | Push to Talk |
| `MWHEELUP / DOWN` | Jump (B-Hop) |
| `Q` | Quick Switch (Last Weapon) |
| `R` | Reload |
| `E` | Use / Interact |
| `F` | Inspect Weapon |
| `G` | Drop Weapon |
| `H` | Switch Viewmodel Hand |
| `1–9 / 0` | Weapon Slots |
| `TAB` | Scoreboard |
| `ENTER` | All Chat |
| `U` | Team Chat |
| `V` | Radial Radio Menu 2 |
| `C` | Radial Radio Menu |
| `Z` | Radio Commands |
| `B` | Custom Alias (`css_b`) |
| `T` | Custom Alias (`css_r`) |
| `M` | Select Team |
| `I` | Toggle Loadout |
| `` ` `` | Toggle Console |
| `F3` | Autobuy |
| `F4` | Rebuy |
| `F5` | Screenshot |
| `F6` | Quick Save |
| `F7` | Quick Load |
| `F10` | Quit Game |
| `DEL` | Sell All (Buy Menu) |
| `]` | Toggle Microphone On/Off |
| `, / .` | Buy Primary / Secondary Ammo |

### config_surf_binds.cfg — Surf

Automatically loaded when connecting to a surf server via alias. Key differences from default:

| Key | Action (Surf) |
|---|---|
| `MWHEELUP / DOWN` | Previous / Next Weapon (not jump) |
| `O` | Turn Left |
| `P` | Turn Right |
| `Q` | Custom Alias (`css_end`) |
| `R` | Custom Alias (`css_rs`) |
| `Z` | RTV (`css_rtv`) |
| `H` | Custom Alias (`css_hide`) |

---

## Aliases & Server Shortcuts

Defined in `config_aliases.cfg`.

### Utility

| Alias | Command | Description |
|---|---|---|
| `cls` | `clear` | Clear the console |
| `radaron` | `cl_drawhud_force_radar 1` | Force radar visible |
| `dc` | `disconnect` | Disconnect from current server |

### Pracc DM — Sydney

| Alias | Server | Map |
|---|---|---|
| `dm` | `121.127.47.34:26764` | Mirage |
| `dm2` | `121.127.47.34:26084` | Dust |

### KZG Surf — Sydney

Automatically execs `config_surf_binds.cfg` before connecting.

| Alias | Server | Difficulty |
|---|---|---|
| `easy` | `103.212.227.45:27030` | Easy |
| `easy2` | `103.212.227.45:27015` | Easy 2 |
| `hard` | `103.212.227.45:27090` | Hard |

### Retakes — Sydney

Automatically execs `config_default_binds.cfg` before connecting (restores binds after surf).

| Alias | Server |
|---|---|
| `retakes1` | `121.127.47.35:26481` |
| `retakes2` | `121.127.47.34:25891` |
| `retakes3` | `121.127.47.33:25048` |
| `retakes4` | `121.127.47.34:25045` |
| `retakes5` | `121.127.47.35:25372` |
| `retakes6` | `121.127.47.33:26958` |

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/mynameistito/CS2-Configs.git "F:\GitHub\mynameistito\CS2-Configs"
```

### 2. Deploy Configs

Run the setup script from any PowerShell window (no need to open as Administrator first):

```powershell
cd "F:\GitHub\mynameistito\CS2-Configs"
.\deploy_configs.ps1
```

If you hit an execution policy error, run this first:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

The script will ask how you want to deploy:

| Option | Description |
|---|---|
| **[1] Symlink** | Links CS2's cfg files directly to the repo. Any `git pull` applies instantly — no re-running the script. The script auto-elevates to Administrator if needed. |
| **[2] Copy** | Copies the files into the CS2 cfg directory. No elevation needed. Re-run the script after each `git pull` to update. |

**Target directory:**
```
C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\
```

### 3. Set Launch Options

In Steam, right-click **Counter-Strike 2 > Properties** and paste into Launch Options:

```
-novid -allow_third_party_software +exec autoexec.cfg
```

### 4. Launch the game

On first load, you should see the following in console confirming all configs executed:

```
ALIASES LOADED
CONVARS CONFIG EXECUTED
ALIASES AND KEY BINDS CONFIG EXECUTED
CROSSHAIR CONFIG LOADED
AUTOEXEC EXECUTED
```

---

## Updating

```bash
git pull
```

- **Symlink mode:** changes are live immediately — just run `exec autoexec.cfg` in console.
- **Copy mode:** re-run `.\deploy_configs.ps1` after pulling to push the updated files into CS2.
