# CS2 Configs

Config files for Counter-Strike 2.

---

## Launch Options

```
-disable_workshop_command_filtering -novid -allow_third_party_software +exec autoexec.cfg
```

| Flag | Purpose |
|---|---|
| `-novid` | Skip the Valve intro video on launch |
| `-allow_third_party_software` | Required for some external tools and overlays |
| `+exec autoexec.cfg` | Force-execute autoexec on every game launch |

In Steam, right-click **Counter-Strike 2 → Properties** and paste into Launch Options.

---

## Files

```
cs2/
├── autoexec.cfg              # Entry point — execs all other configs
├── config_aliases.cfg        # Aliases and server shortcuts
├── config_convars.cfg        # Game settings and convars
├── config_crosshair.cfg      # Crosshair settings
├── config_default_binds.cfg  # Standard competitive / DM binds
├── config_kz_binds.cfg       # KZ-specific binds
├── config_surf_binds.cfg     # Surf binds (swapped in/out via alias)
└── config_allkeys.cfg        # Diagnostic — echoes every key name
```

### autoexec.cfg

Executed on every launch. Loads all other configs in order:

```
exec config_aliases.cfg
exec config_convars.cfg
exec config_default_binds.cfg
exec config_crosshair.cfg
```

---

## Settings

### Mouse & Sensitivity

| Convar | Value | Option Var | Option |
|---|---|---|---|
| `sensitivity` | `0.625` | DPI | `3200`
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

Binds use **scancodes** — layout-independent (works on QWERTY, AZERTY, etc.).

### config_default_binds.cfg — Competitive / DM

| Key | Action |
|---|---|
| `W / A / S / D` | Move Forward / Left / Back / Right |
| `SPACE` | Jump (also B-Hop on scroll wheel) |
| `SHIFT` | Crouch |
| `CTRL` | Walk / Sprint |
| `MOUSE1` | Fire |
| `MOUSE2` | Alt Fire / Scope |
| `MOUSE3` | Ping Location |
| `MOUSE4` | Push to Talk |
| `;` | Voice Record |
| `MWHEELUP / DOWN` | Jump (B-Hop) |
| `Q` | Quick Switch (Last Weapon) |
| `R` | Reload |
| `E` | Use / Interact |
| `F` | Inspect Weapon |
| `G` | Drop Weapon |
| `H` | Switch Viewmodel Hand |
| `1–9 / 0` | Weapon Slots |
| `X` | Slot 12 (Healthshot / Special) |
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
| `[` | Toggle Voice Loopback |
| `, / .` | Buy Primary / Secondary Ammo |

### config_surf_binds.cfg — Surf

Automatically loaded via alias when connecting to a surf server. Key differences from default:

| Key | Action (Surf) |
|---|---|
| `MWHEELUP / DOWN` | Previous / Next Weapon (not jump) |
| `O` | Turn Left |
| `P` | Turn Right |
| `Q` | End Zone Bind (`css_end`) |
| `R` | Restart Stage (`css_rs`) |
| `T` | Restart — Back to Start (`css_r`) |
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
| `dc` | `disconnect` | Disconnect |

### Pracc DM — Sydney

| Alias | Server | Map |
|---|---|---|
| `dm` | `121.127.47.34:26764` | Mirage |
| `dm2` | `121.127.47.34:26084` | Dust |

### Surf — Sydney

#### [KZG Servers](https://join.kzg.gg)

Automatically execs `config_surf_binds.cfg` before connecting.

| Alias | Server IP | Difficulty |
|---|---|---|
| `easy` | `103.212.227.45:27030` | Easy |
| `easy2` | `103.212.227.45:27015` | Easy 2 |
| `hard` | `103.212.227.45:27090` | Hard |

#### [Insanity Gaming](https://insanitygaming.net/forums/)

Automatically execs `config_surf_binds.cfg` before connecting.

| Alias | Server IP |
|---|---|
| `ig` | `103.212.224.9:27015` |

### Retakes — Sydney

[KZG Servers](https://join.kzg.gg) — automatically execs `config_default_binds.cfg` before connecting (restores binds after surf).

| Alias | Server |
|---|---|
| `retakes1` / `rt1` | `121.127.47.35:26481` |
| `retakes2` / `rt2` | `121.127.47.34:25891` |
| `retakes3` / `rt3` | `121.127.47.33:25048` |
| `retakes4` / `rt4` | `121.127.47.34:25045` |
| `retakes5` / `rt5` | `121.127.47.35:25372` |
| `retakes6` / `rt6` | `121.127.47.33:26958` |

### KZ

| Alias | Server |
|---|---|
| `kz` | `121.127.47.34:26855` |
