# My NixOS Configuration

<img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake.svg" align="right" alt="Nix logo" width="150">

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is my personal NixOS configuration, being lapdated since 2019, by using `flakes` and `home-manager`. You will also find a bit of security and privacy configurations in my attempt of improving Linux's desktop. You are welcome to take inspiration :)

#### You will find configurations for:
- Sway (Wayland / xWayland)
- AMD CPU / GPU
- Pipewire
- ZSH
- Dnscrypt
- Systemd Hardened
- Opensnitch
- Bwrap (browsers, telegram, discord, steam)
- Neovim
- XDG 
- Themes

## Design

```
flake.nix              -- entry point, merges everything bellow
   |
   |--> profiles/*     -- high-level configuration, the "user profile"
   |--> hardwares/*    -- configs specific by hardware
   |
   |--> modules/*      -- modules to compose the "profiles/*" and "hardwares/*",
   |                   -- defines the custom "myNix" options
   |
   |--> overlays/*     -- define new or override packages
   |--> lib/*          -- custom functions and abstractions for everything above (eg: bwrapIt)
```

## Install

If you want a full disk reset:
```bash
# download script from _scripts/setup_disk.sh
curl -L setup-disk.shiryel.com > setup.sh
chmod +x setup.sh

# run it
./_scripts/setup_disk.sh /dev/YOUR_DEVICE_HERE
```

If you already have a system formated, add your `hardware_config.nix` to `system/hardware/hardware-configuration.nix` and run:
```bash
sudo nixos-rebuild switch --flake .#generic
```

## Inspiration

You can get started with flakes here: https://nixos.wiki/wiki/Flakes
Also, you may want to take a look on the flakes that I took inspiration:
- https://github.com/ners/NixOS
- https://github.com/balsoft/nixos-config
- https://github.com/Kranzes/nix-config
- https://github.com/jonringer/nixpkgs-config
- https://github.com/sebastiant/dotfiles
- https://github.com/kotokrad/dotfiles (fennel nvim!)
- https://github.com/ericdallo/dotfiles (android / flutter configs)

## Testing

#### Workspaces
- `xrandr` - check if primary on a output with 16:9 aspect ratio
- `record` - check if screen recording is working on every workspace

#### Network
- `dig +short txt qnamemintest.internet.nl` - check if QNAME minimisation is enabled
- `sudo cat /var/log/dnscrypt-proxy/dnscrypt-proxy.log` - check if dnscrypt is choosing a good DNS server with low latency
- `ssh -T git@github.com` - check if ssh, gpg and pinentry are working
- `https://www.cloudflare.com/ssl/encrypted-sni/` - check DNSSEC (SNI will be unsuported)

#### Systemd
- `systemctl --user --type=target` - check available user targets
- `systemctl --user --failed` - check failed user services
- `systemctl --failed` - check failed system services
- `systemd-analyze security` - check system security
- `systemd-analyze security --user` - check user security

#### Debuging Tools
- ldd - check dynamic executables (notice that ldd is wrapped in a hard-coded loader that always reports its own path no matter what loader path the program has expected, eg: /lib/ld-linux.so.2 != /lib/ld-lsb.so.3)
- LD_DEBUG=all $COMMAND
- objdump -j .interp -s $COMMAND
- strace
- ftrace
- perf

#### Debug Envs
- NIX_DEBUG=true 
- WAYLAND_DEBUG=1 
- XDG_UTILS_DEBUG_LEVEL=10 
- QT_DEBUG_PLUGINS=1 
- GTK_DEBUG=interactive

#### Security Tools (not installed)
- chkrootkit
- lynis

##

<p align=center>
   <img src=".assets/shiryel_by_lucky.png" alt="Nix Shiryel, drawing by Lucky Blackat" height="800">  
   <br/><em>by Lucky Blackat</em>
</p>
