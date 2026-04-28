# Installing Software Leverage Points for Codex

Enable software-leverage-points skills in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git

## Installation

1. **Clone the software-leverage-points repository:**
   ```bash
   git clone https://github.com/NeuralEmpowerment/software-leverage-points.git ~/.codex/software-leverage-points
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/software-leverage-points/skills ~/.agents/skills/software-leverage-points
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\software-leverage-points" "$env:USERPROFILE\.codex\software-leverage-points\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/software-leverage-points
```

You should see a symlink (or junction on Windows) pointing to your software-leverage-points skills directory.

## Updating

```bash
cd ~/.codex/software-leverage-points && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/software-leverage-points
```

Optionally delete the clone: `rm -rf ~/.codex/software-leverage-points`.
