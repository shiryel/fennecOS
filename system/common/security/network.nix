###########################################################
# This file configures your online privacy, with:
# - dnscrypt-proxy2
# - networkd
#
# TEST:
# - To test Systemd
#   networkctl
#   systemctl --type=service
#
# - To see the logs from DNSCrypt with:
#   sudo cat /var/log/dnscrypt-proxy/dnscrypt-proxy.log
#
# - To test if it works as expected:
#   dig +short txt qnamemintest.internet.nl
#   https://www.cloudflare.com/ssl/encrypted-sni/
#   https://www.youtube.com/watch?v=2oe0_v5M8cE
#
# - To simulate a pi-hole
#   https://github.com/NixOS/nixpkgs/issues/61617
#
# NOTES:
# - ESNI support is only from the browser:
#   https://github.com/DNSCrypt/dnscrypt-proxy/issues/941
#
# DOCS:
# - https://nixos.wiki/wiki/Encrypted_DNS
# - https://wiki.archlinux.org/title/Systemd-networkd
#
###########################################################

{ lib, pkgs, pkgs_unstable, ... }:

{
  networking = {
    firewall = {
      enable = true;
      # 14159 -> Necesse
      # 15937 -> RAOT
      # 64640 -> Bomberman
      allowedTCPPorts = [ 14159 15937 64640 ];
      allowedUDPPorts = [ 14159 15937 64640 ];
    };
    # - configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  ######################
  # OpenSnich Firewall #
  ######################

  services = {
    opensnitch = {
      enable = true;
      settings = {
        Firewall = "iptables";
        DefaultDuration = "15m";
        DefaultAction = "deny";
        ProcMonitorMethod = "ebpf";
      };
    };
  };

  # integrates ebpf
  environment.etc."opensnitchd/opensnitch.o".source = "${pkgs.opensnitch_ebpf}/etc/opensnitchd/opensnitch.o";

  environment.systemPackages = with pkgs; [
    opensnitch-ui
  ];

  # does not have access to the network as specified bellow
  # by systemd.services
  services.nscd.enableNsncd = true;

  # /var/lib/opensnitch/rules/*
  systemd.tmpfiles.rules = with pkgs._no_bwrap;
    let
      no_bwrap_unstable = pkgs_unstable._no_bwrap;
    in
    [
      # Allow:
      (lib.snitchAllowIp "127.0.0.1")
      (lib.snitchAllowPath "${nixFlakes}/bin/nix")
      (lib.snitchAllowPath "${networkmanager}/bin/NetworkManager")
      (lib.snitchAllowPath "${systemd}/lib/systemd/systemd-timesyncd")
      (lib.snitchAllowPath "${firefox}/lib/firefox/firefox")
      (lib.snitchAllowPath "${dnscrypt-proxy2}/bin/dnscrypt-proxy")
      (lib.snitchAllowPath "${no_bwrap_unstable.tdesktop}/bin/.telegram-desktop-wrapped")
      (lib.snitchAllowPath "${no_bwrap_unstable.discord-canary}/opt/DiscordCanary/.DiscordCanary-wrapped")
      (lib.snitchRule "allow" "steam" "/home/shiryel/.local/share/Steam/ubuntu12_32/steam")
      (lib.snitchRule "allow" "steamerrorreporter" "/home/shiryel/.local/share/Steam/linux32/steamerrorreporter")
      (lib.snitchRule "allow" "steamwebhelper" "/home/shiryel/.local/share/Steam/ubuntu12_64/steamwebhelper")
      #(lib.snitchAllowPath "${clamav}/bin/freshclam")
      # Deny:
      # Does not trully impact in anything, and after disabling dnscrypt [1]
      # it does not look that it is bypassing it, but just to be safe...
      # [1] - sudo pkill -STOP dnscrypt-proxy
      #     - sudo pkill -CONT dnscrypt-proxy
      (lib.snitchDenyPath "${glibc}/bin/nscd")
      #(lib.snitchDenyPath "${nsncd}/bin/nsncd")
      (lib.snitchAllowPath "${nsncd}/bin/nsncd")
      # file picker uses gvfs to send broadcast requests (192.168.1.255)
      (lib.snitchDenyPath "${gvfs}/libexec/.gvfsd-smb-browse-wrapped")
      (lib.snitchDenyPath "${pkgs_unstable.gvfs}/libexec/.gvfsd-smb-browse-wrapped")
    ];

  #############################
  # DNSCrypt + NetworkManager #
  #############################
  # NOTE:
  # Some Networkd configuration examples can be found at `notes.md`

  # started from sway, so we can have the tray-icon
  programs.nm-applet.enable = false;

  networking = {
    networkmanager = {
      enable = true;
      ethernet.macAddress = "random";
      wifi.scanRandMacAddress = true;
    };
    wireless.userControlled.enable = false; # TODO: true for notebook
    # explicity disable dhcpcd 
    useDHCP = false;
    dhcpcd.enable = false;
    ################################################
    # defaults for DNSCrypt (both DHCP and Networkd)
    nameservers = [ "127.0.0.1" "::1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
    ################################################
  };

  # Do not wait for a network connection to start the system
  # (adds +6 seconds to the `systemd-analyze critical-chain`)
  #systemd.services.NetworkManager-wait-online.enable = false;

  users.extraGroups.networkmanager.members = [ "shiryel" "admin" ];

  services = {
    resolved.enable = false;

    dnscrypt-proxy2 = {
      enable = true;
      settings = {
        log_file = "/var/log/dnscrypt-proxy/dnscrypt-proxy.log";
        log_file_latest = true;

        ipv6_servers = true;
        dnscrypt_servers = true;
        doh_servers = true;
        require_dnssec = true;

        # Cache
        # https://00f.net/2019/11/03/stop-using-low-dns-ttls/
        cache = true;
        cache_size = 8192;
        cache_min_ttl = 86400; # 1 day
        cache_max_ttl = 604800; # 7 days
        cache_neg_min_ttl = 60; # 1 min
        cache_neg_max_ttl = 600; # 10 min

        # - To a faster startup when configuring this file
        # - You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        # server_names = [ "nextdns" "nextdns-ipv6" "cloudflare" "cloudflare-ipv6" ];

        ###############
        # ODoH Config #
        ###############
        # (WIP)
        #
        # CAUTION: 
        # - ODoH relays cannot be used with DNSCrypt servers, 
        # - DNSCrypt relays cannot be used to connect to ODoH servers.
        # - ODoH relays can only connect to servers supporting the ODoH protocol, not regular DoH servers.
        # In other words, only combine ODoH relays with ODoH servers.
        #
        # odoh_servers = true;
        #
        # sources.odoh-servers =
        #   {
        #     urls = [
        #       "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md"
        #       "https://download.dnscrypt.info/resolvers-list/v3/odoh-servers.md"
        #       "https://ipv6.download.dnscrypt.info/resolvers-list/v3/odoh-servers.md"
        #     ];
        #     cache_file = "odoh-servers.md";
        #     minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        #     refresh_delay = 24;
        #   };
        # sources.odoh-relays = {
        #   urls = [
        #     "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md"
        #     "https://download.dnscrypt.info/resolvers-list/v3/odoh-relays.md"
        #     "https://ipv6.download.dnscrypt.info/resolvers-list/v3/odoh-relays.md"
        #   ];
        #   cache_file = "odoh-relays.md";
        #   minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        #   refresh_delay = 24;
        # };
      };
    };
  };
}
