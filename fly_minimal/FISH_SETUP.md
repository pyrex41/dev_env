# Fish Shell on Fly.io - Setup Complete! 🐟

## ✅ What's Working

Your Fly.io machine now has Fish shell fully configured:

- **Fish 3.6.3** installed and set as default shell for `testuser`
- **SSH access** through Fly's proxy working correctly
- **Local Fish functions** ready to use
- **Sync script** created for pushing your Fish config

## Quick Start

### Connect to the Machine

```bash
# Start in a new Zellij pane (or any terminal)
fly ssh console -a wander-test-minimal --user testuser

# Or use the convenience function (in Fish shell locally):
flyfish
```

You'll drop straight into Fish shell with colors!

### Sync Your Fish Config

```bash
# From your local machine (in Fish shell):
fly-sync

# Or directly:
~/bin/fly-fish-sync.sh wander-test-minimal
```

This will copy your local `~/.config/fish/` to the remote machine, including:
- All your functions (gw, grw, gm, up, down, etc.)
- Your prompt theme
- Color settings
- Abbreviations

## Local Setup Details

### Fish Functions Added

In your `~/.config/fish/config.fish`:

```fish
function flyfish
    if test (count $argv) -eq 0
        fly ssh console -a wander-test-minimal
    else
        fly ssh console -a $argv[1]
    end
end

function fly-sync
    if test (count $argv) -eq 0
        ~/bin/fly-fish-sync.sh wander-test-minimal
    else
        ~/bin/fly-fish-sync.sh $argv[1]
    end
end
```

### Sync Script Location

`~/bin/fly-fish-sync.sh` - Executable script that:
1. Creates tar archive of your Fish config
2. Uploads to remote machine
3. Extracts and sets permissions
4. Sets Fish color variables

### SSH Config

Your `~/.ssh/config` includes:
```
Host fly-*
    SendEnv TERM
    SetEnv TERM=xterm-256color
```

This ensures 256-color support is passed through SSH for proper theme rendering.

## Remote Machine Details

### User: testuser
- **Default Shell**: `/usr/bin/fish`
- **Home**: `/home/testuser/`
- **Workspace**: `/home/testuser/workspace/`
- **Sudo**: Passwordless sudo enabled
- **SSH Key**: Your `~/.ssh/id_ed25519.pub` is authorized

### Installed Packages
- Alpine Linux 3.19
- Fish 3.6.3
- OpenSSH
- Bash (backup)
- Git, curl, wget, sudo

## Usage in Zellij

### Open Fish Session in New Pane

```bash
# 1. In Zellij, create a new pane:
Ctrl+p, then 'n' (new pane)
# or
Ctrl+p, then 's' (split horizontal)
# or
Ctrl+p, then 'v' (split vertical)

# 2. In the new pane, run:
flyfish

# 3. You're now in Fish on the Fly machine!
# The pane looks native - same borders, same layout
```

### Colors and Themes

Since `TERM=xterm-256color` is passed through SSH, your Fish theme will render properly with:
- Syntax highlighting
- Directory colors
- Git status colors
- Auto-suggestion colors

## Testing

```bash
# Connect
fly ssh console -a wander-test-minimal --user testuser

# Verify Fish version
fish --version
# Output: fish, version 3.6.3

# Check working directory
pwd
# Output: /

# Go home
cd ~
pwd
# Output: /home/testuser

# Check workspace
ls -la ~/workspace/
# Output: empty directory ready for your projects

# Test a command with Fish syntax
echo "Hello from Fish!" | string upper
# Output: HELLO FROM FISH!
```

## Workflow Example

### 1. Local Terminal (Fish)
```fish
# Sync your config first time
fly-sync

# Open connection in Zellij pane
flyfish
```

### 2. Remote Fish Session
```fish
# Now you have all your aliases/functions!
cd ~/workspace

# Clone a repo
git clone https://github.com/yourname/yourrepo.git
cd yourrepo

# Your custom Fish functions work here too
# (if you synced your config)
```

### 3. Update Config
```fish
# Make changes locally to ~/.config/fish/config.fish
# Then re-sync:
fly-sync

# Reconnect or reload in remote session:
source ~/.config/fish/config.fish
```

## Machine Management

```bash
# Check status
fly status -a wander-test-minimal

# Start (if stopped)
fly machines start e7847965b101d8 -a wander-test-minimal

# Stop (to save costs)
fly machines stop e7847965b101d8 -a wander-test-minimal

# Restart
fly machines restart e7847965b101d8 -a wander-test-minimal

# View logs
fly logs -a wander-test-minimal -n

# Redeploy (for fresh start)
cd /Users/reuben/gauntlet/dev_env/fly_minimal
fly deploy
```

## Files Modified

### Local Files
- `~/.config/fish/config.fish` - Added flyfish and fly-sync functions
- `~/.ssh/config` - Already had TERM config for fly-* hosts
- `~/bin/fly-fish-sync.sh` - New sync script (executable)

### Remote Files (in Docker image)
- `/Users/reuben/gauntlet/dev_env/fly_minimal/Dockerfile` - Added Fish, removed SSHD daemon
- `/Users/reuben/gauntlet/dev_env/fly_minimal/fly.toml` - Updated service config
- `/Users/reuben/gauntlet/dev_env/fly_minimal/README.md` - Updated with Fish info

## Troubleshooting

### Can't Connect
```bash
# Check if machine is running
fly status -a wander-test-minimal

# Start it
fly machines start e7847965b101d8 -a wander-test-minimal

# Wait a few seconds, then try again
flyfish
```

### Colors Not Working
```bash
# Check TERM locally
echo $TERM
# Should be: xterm-256color or alacritty

# Check TERM remotely
fly ssh console -a wander-test-minimal --user testuser -C "echo \$TERM"
# Should be: xterm-256color

# If not set, check ~/.ssh/config has:
# Host fly-*
#     SetEnv TERM=xterm-256color
```

### Fish Config Not Syncing
```bash
# Check local config exists
ls -la ~/.config/fish/

# Run sync with debug
~/bin/fly-fish-sync.sh wander-test-minimal

# Manually verify on remote
flyfish
ls -la ~/.config/fish/
```

### Machine Keeps Stopping
This is normal! The machine auto-stops when idle to save costs. It will auto-start when you connect via `flyfish`.

To keep it running:
```bash
fly machines update e7847965b101d8 -a wander-test-minimal --auto-stop-machines=false
```

## Cost

With auto-stop enabled:
- **When stopped**: $0.00/hour
- **When running**: ~$0.001/hour (~$0.75/month if always on)
- **Storage**: $0.00 (no volumes)

Typical usage (1-2 hours/day): **~$0.05-$0.10/month**

## Next Steps

1. **Customize Fish**: Edit `~/.config/fish/config.fish` locally, then `fly-sync`
2. **Install Tools**: SSH in and `apk add` whatever you need (temporary until redeploy)
3. **Persistent Tools**: Add to Dockerfile, then `fly deploy`
4. **Try in Zellij**: Open pane, `flyfish`, enjoy native look-and-feel

---

**You're all set!** Fish shell is ready on your Fly machine with colors, your local config sync, and seamless Zellij integration.

Run `flyfish` from any Zellij pane to get started! 🚀
