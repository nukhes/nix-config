# nix-config

nixos configuration for pedro henrique.

## hosts

| host | machine | arch | role |
|------|---------|------|------|
| `x99` | xeon x99 desktop | x86_64-linux | main workstation, build server |
| `x200` | thinkpad x200 | x86_64-linux | lightweight laptop |
| `hackbook` | macbook (hackintosh) | x86_64-linux | portable workstation |
| `darwin` | macbook | aarch64-darwin | macos workstation |

## structure

```
.
├── flake.nix                    # entrypoint — auto-imports all .nix under modules/
├── flake.lock
├── secrets.nix                  # agenix key declarations
├── secrets/                     # encrypted .age files
├── bootstrap.sh                 # first-install script
└── modules/
    ├── options.nix              # flake-parts option declarations (deferredModule)
    ├── hosts/                   # per-host nixosSystem definitions
    │   ├── x99.nix
    │   ├── x200.nix
    │   ├── hackbook.nix
    │   └── darwin.nix
    ├── nixos/                   # system-level modules
    │   ├── nix-settings.nix     # common nix daemon config (caches, gc, trusted-users)
    │   ├── services.nix         # common services (ssh, pipewire, tailscale, i3, etc.)
    │   ├── user.nix             # user account, home-manager bootstrap
    │   ├── desktop.nix          # gui packages (thunar, dconf, virtualbox)
    │   ├── power-tweaks.nix     # laptop power management (tlp, powertop)
    │   ├── x99.nix              # x99-specific (xrandr, cpu governor)
    │   ├── x200.nix             # x200-specific (thinkfan, zram, journald)
    │   ├── hackbook.nix         # hackbook-specific (mbpfan, prochot)
    │   ├── *-hardware.pkg.nix   # hardware-configuration (callPackage, excluded from auto-import)
    │   └── *-kernel.nix         # per-host kernel config
    └── hm/                      # home-manager modules
        ├── base.nix             # common hm packages and dotfiles
        └── ...                  # per-app modules (neovim, firefox, i3, etc.)
```

the flake uses `flake-parts` with a recursive auto-importer. every `.nix` file under
`modules/` is imported automatically, except files matching `*.pkg.nix` (those are
consumed via `callPackage` / direct import inside other modules).

host-specific config is wired through `deferredModule` options declared in `options.nix`
(e.g. `nixos.modules.x200`, `nixos.modules.common`), then referenced in each host
definition under `modules/hosts/`.

## bootstrap (fresh install)

on a fresh nixos installation with network access:

```bash
# ensure ssh keys are placed at /etc/ssh/ and ~/.ssh/ before running
sh -c "$(curl -sSL https://raw.githubusercontent.com/nukhes/nix-config/refs/heads/master/bootstrap.sh)"
```

this clones the repo to `~/.nix-config` and runs `nixos-rebuild switch --flake .#$(hostname)`.

## local rebuild

```bash
cd ~/.nix-config
sudo nixos-rebuild switch --flake .#$(hostname)
```

## remote build and deploy

this procedure builds a nixos configuration locally on a more powerful machine (the
build host) and deploys the resulting closure to a remote target over ssh. this is
useful when the target machine is too slow to compile its own configuration — for
example, building the `x200` config on the `x99`.

### prerequisites

all of the following must be true before running the remote deploy command:

1. **both machines are on the same network** (or reachable via tailscale).

2. **the build host has the flake repository** cloned and up to date at `~/.nix-config`.

3. **sshd is running on the target host.** the config enables `services.openssh.enable = true`
   in the common module, but after a fresh install the service may not be active yet.
   verify and start it on the target if needed:

   ```bash
   sudo systemctl enable --now sshd
   sudo systemctl status sshd
   ```

4. **the build host's ssh public key is authorized on the target.** from the build host:

   ```bash
   ssh-copy-id user@<target-ip>
   ```

   verify passwordless login works:

   ```bash
   ssh user@<target-ip> hostname
   ```

5. **the target user can run sudo.** the `user` account is in the `wheel` group by
   default. if `sudo` requires a password, `nixos-rebuild` will prompt for it
   interactively. alternatively, use `root@<target-ip>` as the target host to skip
   sudo entirely.

6. **the target accepts unsigned store paths from trusted users.** the common nix
   config sets `nix.settings.trusted-users = [ "root" "user" ]`, which allows
   `nixos-rebuild` to copy paths into the target's nix store without requiring
   a signing key.

### build locally, deploy remotely

run from the build host (e.g. `x99`):

```bash
cd ~/.nix-config

nixos-rebuild switch \
  --flake .#<target-hostname> \
  --target-host user@<target-ip> \
  --elevate=sudo
```

concrete example — build `x200` on `x99`, deploy to `192.168.1.110`:

```bash
nixos-rebuild switch \
  --flake .#x200 \
  --target-host user@192.168.1.110 \
  --elevate=sudo
```

what happens under the hood:

1. `nix build` evaluates and builds the `x200` configuration **locally on the build host**,
   using all available cores.
2. `nix copy --to ssh://user@<target-ip>` transfers the resulting store closure to
   the target machine over ssh.
3. `nixos-rebuild` runs the activation script on the target via `ssh` with `sudo`,
   switching the system to the new configuration.

### flag reference

| flag | effect |
|------|--------|
| `--flake .#<host>` | evaluate the nixos configuration named `<host>` from the local flake |
| `--target-host user@<ip>` | deploy to this machine over ssh (copy closure + activate) |
| `--build-host localhost` | build on the local machine (this is the default) |
| `--build-host user@<ip>` | build on the remote machine instead of locally |
| `--elevate=sudo` | run activation commands on the target with `sudo` |

### testing without activating

to build and copy without switching (useful to verify the build succeeds):

```bash
nixos-rebuild build \
  --flake .#x200 \
  --target-host user@192.168.1.110 \
  --elevate=sudo
```

to build, copy, and create a boot entry without switching the running system:

```bash
nixos-rebuild boot \
  --flake .#x200 \
  --target-host user@192.168.1.110 \
  --elevate=sudo
```

### troubleshooting

**ssh connection refused or filtered:**
the target firewall may be blocking port 22. nixos opens port 22 automatically when
`services.openssh.enable = true`, but if the config hasn't been applied yet, open it
manually:

```bash
# on the target
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
```

**"cannot add path ... because it lacks a signature":**
ensure `nix.settings.trusted-users` includes the user performing the deploy on the
target machine. this is set in `modules/nixos/nix-settings.nix`.

**slow transfer or broken pipe:**
large closures over wifi can be slow and prone to disconnects. prefer a wired
connection when deploying full system rebuilds. if the connection drops (`broken pipe`),
add ssh keepalive settings to `~/.ssh/config`:
```ssh-config
Host <target-ip>
  ServerAliveInterval 15
  ServerAliveCountMax 10
```

**"ca hash mismatch importing path ...":**
a store path on the local build host may be corrupted. verify and repair it locally
before retrying the deploy:
```bash
sudo nix store verify --repair /nix/store/<hash>-<name>
```

**home-manager-user.service fails with exit-code 128:**
this usually happens if home-manager is trying to clone a git repository (e.g. via ssh)
but the target user's private ssh key (`~/.ssh/id_ed25519`) has permissions that are too open
(like `0755`). ssh ignores the key for security, git fails to clone, and the activation aborts.
fix the permissions on the target machine:
```bash
# on the target
sudo chmod 700 /home/user/.ssh
sudo chmod 600 /home/user/.ssh/id_ed25519
```

## secrets management

secrets are encrypted with [agenix](https://github.com/ryantm/agenix). public keys
for decryption are declared in `secrets.nix`. each host's `/etc/ssh/ssh_host_ed25519_key`
is used as the decryption identity (configured in `modules/nixos/user.nix`).

to add a new secret:

```bash
cd ~/.nix-config
agenix -e secrets/<name>.age
```

### provisioning secrets for a new host

when deploying to a new machine (like the `x200`) for the first time, its auto-generated
ssh host key must be added to agenix so it can decrypt secrets (e.g. tailscale auth keys).

1. do the initial deploy. services depending on secrets will fail (e.g. `exit status 4`).
2. retrieve the new host's public key:
   ```bash
   ssh root@<new-host-ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub'
   ```
3. add the key to `secrets.nix` and include it in the `publicKeys` list.
4. re-key all secrets using the agenix cli:
   ```bash
   cd ~/.nix-config
   nix run github:ryantm/agenix -- -r
   ```
5. run the deploy command again to start the failing services.

> **security warning**: do not copy `/etc/ssh/ssh_host_*` files from an existing machine
> to the new one just to bypass this process. doing so will break ssh identity caching
> (`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED`) because multiple machines on your
> network will share the same cryptographic identity. always re-key instead.
