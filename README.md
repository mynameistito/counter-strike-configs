# Counter-Strike Configs — mynameistito

Personal config files for CS2, CSGO (legacy), and Counter-Strike: Source — managed via Git and deployed with a TypeScript CLI.

**Steam:** [steamcommunity.com/id/mynameistito](https://steamcommunity.com/id/mynameistito/)

![social preview](assets/social-preview.png)

---

## File Structure

```
counter-strike-configs/
├── cs2/               # Counter-Strike 2
├── csgo/              # Counter-Strike: Global Offensive (legacy) — coming soon
├── css/               # Counter-Strike: Source
├── src/deploy.ts      # Deployment CLI (symlink or copy)
├── package.json
└── assets/
```

See each folder's README for game-specific launch options, settings, and binds:

- [`cs2/README.md`](cs2/README.md)
- [`css/README.md`](css/README.md)
- [`csgo/README.md`](csgo/README.md)

---

## Installation

### 1. Clone

```bash
git clone https://github.com/mynameistito/CS2-Configs.git
cd CS2-Configs
```

### 2. Install

Requires [Node.js](https://nodejs.org/) 18+.

```bash
npm install
```

### 3. Deploy

```bash
npm run deploy
```

The CLI prompts for game and mode interactively, or skip prompts by passing flags:

```bash
npm run deploy -- --game cs2 --mode copy
npm run deploy -- --game all --mode symlink
```

**`--game` / `-g`**

| Value | Description |
|---|---|
| `cs2` | Counter-Strike 2 |
| `csgo` | Counter-Strike: Global Offensive (legacy) |
| `css` | Counter-Strike: Source |
| `all` | All installed games |

**`--mode` / `-m`**

| Value | Description |
|---|---|
| `symlink` | Links cfg files directly into the repo. `git pull` applies instantly. Auto-elevates to Admin on Windows. |
| `copy` | Copies files into the game directory. No elevation needed. Re-run after each `git pull`. |

> [!CAUTION]
> **Symlink mode:** cfg files point directly into the cloned repo. If you move, rename, or delete the repo, all symlinks break. Keep the repo in a stable location.

**Target directories** are auto-detected from the Steam registry:

| Game | Path |
|---|---|
| CS2 | `<Steam>\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\` |
| CSGO | `<Steam>\steamapps\common\Counter-Strike Global Offensive\csgo\cfg\` |
| CSS | `<Steam>\steamapps\common\Counter-Strike Source\cstrike\cfg\` |

---

## Updating

```bash
git pull
```

- **Symlink mode:** changes apply immediately — run `exec autoexec.cfg` in console.
- **Copy mode:** re-run `npm run deploy` after pulling.
