# Counter-Strike: Source (CS:S) Configs

Config files for Counter-Strike: Source.

---

## Launch Options

```
-novid -console -high -nojoy -USEALLAVAILABLECORES -softparticlesdefaultoff -nod3d9ex +rate 100000 +cl_updaterate 100 +cl_cmdrate 100 +cl_interp 0 +cl_interp_ratio 1 +cl_smoothtime 0.01
```

| Flag | Purpose |
|---|---|
| `-novid` | Skip the intro video on launch |
| `-console` | Open the console automatically on launch |
| `-high` | Set process to high CPU priority |
| `-nojoy` | Disable joystick support (faster startup) |
| `-USEALLAVAILABLECORES` | Use all available CPU cores |
| `-softparticlesdefaultoff` | Disable soft particles (performance) |
| `-nod3d9ex` | Disable D3D9Ex (improves alt-tab on some systems) |
| `+rate 100000` | Max network data rate |
| `+cl_updaterate 100` | Server update rate |
| `+cl_cmdrate 100` | Client command send rate |
| `+cl_interp 0` | Minimum interpolation |
| `+cl_interp_ratio 1` | Interpolation ratio |
| `+cl_smoothtime 0.01` | View smoothing time |

In Steam, right-click **Counter-Strike: Source → Properties** and paste into Launch Options.

---

## Files

```
css/
├── autoexec.cfg              # Entry point — execs all other configs
├── config_aliases.cfg        # Utility aliases and server shortcuts
├── config_convars.cfg        # Network and game settings
├── config_default_binds.cfg  # Standard binds
├── config_bhop_binds.cfg     # Bhop binds (r → sm_r)
└── config_surf_binds.cfg     # Surf binds
```

### autoexec.cfg

```
exec config_aliases.cfg
exec config_convars.cfg
exec config_default_binds.cfg
```

The autoexec loads the aliases, convars, and default binds. Use the server aliases below to switch to the bhop or surf bind set.

---

## Key Binds

### config_default_binds.cfg

| Key | Action |
|---|---|
| `W / A / S / D` | Move Forward / Left / Back / Right |
| `SPACE` | Jump |
| `SHIFT` | Walk (speed) |
| `CTRL` | Duck |
| `MOUSE1` | Fire |
| `MOUSE2` | Alt Fire |
| `MOUSE3` | Ping |
| `MWHEELUP / DOWN` | Jump (B-Hop) |
| `Q` | Last Inventory |
| `R` | Reload |
| `E` | Use |
| `F` | Flashlight (`impulse 100`) |
| `G` | Drop Weapon |
| `B` | Buy Menu |
| `T` | Spray (`impulse 201`) |
| `O` | Turn Left (`+left`) |
| `P` | Turn Right (`+right`) |
| `U` | Team Chat |
| `V` | Toggle Viewmodel Hand |
| `N` | Night Vision |
| `]` | Toggle Microphone On/Off |
| `;` | Voice Record |
| `` ` `` | Toggle Console |
| `, / .` | Buy Primary / Secondary Ammo |
| `TAB` | Scoreboard |
| `ENTER` | All Chat |
| `DEL` | Mute |
| `1–9 / 0` | Weapon Slots |
| `F1` | Autobuy |
| `F2` | Rebuy |
| `F5` | Screenshot |
| `F6` | Quick Save |
| `F7` | Quick Load |
| `F10` | Quit |

### config_bhop_binds.cfg

Same as default with one difference:

| Key | Default | Bhop |
|---|---|---|
| `R` | `+reload` | `sm_r` (bhop reset) |

---

## Aliases & Server Shortcuts

Defined in `config_aliases.cfg`. Enter an alias in the developer console to run it.

### Utility

| Alias | Command | Description |
|---|---|---|
| `dc` | `disconnect` | Disconnect |
| `cls` | `clear` | Clear the console |

### Servers

| Alias | Server | Bind config |
|---|---|---|
| `bhop` | `51.161.218.252:27051` | `config_bhop_binds.cfg` |
| `priv` | `139.99.149.210:27060` | Surf binds (`config_surf_binds.cfg`) |
