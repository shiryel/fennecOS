## How to downgrade NixOS

Go to https://hydra.nixos.org/jobset/nixos/trunk-combined
Find the input change commit that fix your issue (usually the one with less failures)
Copy it and paste on github, like: https://github.com/NixOS/nixpkgs/tree/bf744fe9
Open any other file and copy the full hash from the URL
Substitute the flake.lock hash with it

### Firefox/Librewolf 
- https://blog.cloudflare.com/oblivious-dns/
- about:config  
- network.trr.odoh.enabled

## Override a home-manager module
```nix
  # !!! WARNING: OVERRIDING NEOVIM CONFIG !!!
  imports = [ ./nvim_override.nix ];
  disabledModules = [ "programs/neovim.nix" ];
  # !!! --------------------------------- !!!
```

## Alowing user-a to `su` on user-b without password

Tutorials:
- https://unix.stackexchange.com/questions/113754/allow-user1-to-su-user2-without-password
- https://stackoverflow.com/questions/45575297/how-do-i-append-text-to-a-etc-configuration-file-in-nixos

```nix
security.pam.services.su.text = lib.mkDefault
  (lib.mkAfter
    ''
      auth  [success=ignore default=1] pam_succeed_if.so user = user-b
      auth  sufficient                 pam_succeed_if.so use_uid user = user-a
    ''
  );
```

## Alowing user-a to `sudo` on user-b without password

```nix
security.sudo.extraConfig = ''
  user-a ALL=(user-b:user-b) NOPASSWD:ALL
''; # maybe use security.sudo.extraRules ?
```

## Automatic SSH-agent authentication on su (or sudo)

```nix
# eval $(ssh-agent)
# ssh-add
security.pam.services.su.sshAgentAuth = true;
security.pam.enableSSHAgentAuth = true;
```

## Use unstable options

- Without flakes:
```nix
imports = [ <nixos-unstable/nixos/modules/programs/firejail.nix> ];
disabledModules = [ "programs/firejail.nix" ];
```

- With flakes:
```nix
imports = [ "${channels.nixpkgs_unstable}/nixos/modules/programs/firejail.nix" ];
disabledModules = [ "programs/firejail.nix" ];
```

## NetworkD with random MAC address config
```nix
  # Use `networkctl` to debug
  networking.useNetworkd = true;

  # - configures random MAC addrres
  # - explicity settup DNS configs to use DNSCrypt
  # - combines Ethernet with Wifi
  systemd.network = {
    enable = true;

    links = {
      "00-random-mac" = {
        enable = true;
        matchConfig.OriginalName = "*";
        linkConfig.MACAddressPolicy = "random";
      };
    };

    netdevs = {
      "10-bond0" = {
        enable = true;
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
        };
        bondConfig = {
          Mode = "active-backup";
          PrimaryReselectPolicy = "always";
          MIIMonitorSec = "1s";
        };
      };
    };

    networks = {
      "10-bond0" = {
        enable = true;
        matchConfig.Name = "bond0";
        DHCP = "yes";
        dhcpV4Config = {
          UseDNS = false;
          Anonymize = true;
          UseDomains = false;
        };
        dhcpV6Config = {
          UseDNS = false;
        };
        networkConfig = {
          IPv6PrivacyExtensions = true;
          DNSSEC = true;
        };
        dns = [ "127.0.0.1" "::1" ];
      };

      "10-ethernet-bond0" = {
        enable = true;
        matchConfig.Type = "ether";
        bond = [ "bond0" ];
        networkConfig.PrimarySlave = true;
      };

      "10-wifi-bond0" = {
        enable = true;
        matchConfig.Type = "wlan";
        bond = [ "bond0" ];
      };
    };
  };
```

## Miscelaneous tutorials

Security
- https://www.kicksecure.com/wiki/Dev/Strong_Linux_User_Account_Isolation
- https://debian-handbook.info/browse/pt-BR/stable/sect.selinux.html

Tutorial: Isolated Linux User
- https://www.burnison.ca/articles/running-firefox-as-an-isolated-linux-user
- https://wiki.gentoo.org/wiki/Wayland#Running_Wayland_or_X11_applications_as_a_different_user
- https://wiki.archlinux.org/title/wayland
- https://bbs.archlinux.org/viewtopic.php?id=273201
- https://unix.stackexchange.com/questions/232669/how-can-i-run-a-program-as-another-user-in-every-way
- https://www.tecmint.com/switch-user-account-without-password/

Tutorial: Isolated Linux using containers
- https://discourse.nixos.org/t/use-home-manager-inside-a-nixos-container-flakes/17850
- https://msucharski.eu/posts/application-isolation-nixos-containers/
