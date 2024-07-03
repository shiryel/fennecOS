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

{ config, lib, pkgs, ... }:

assert builtins.hasAttr "snitchAllowPath" lib;

{
  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
      #allowPing = false;
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

  systemd.user.services.opensnitch-ui = {
    description = "Opensnitch ui";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.opensnitch-ui}/bin/opensnitch-ui";
    };
  };

  services = {
    opensnitch = {
      enable = true;
      settings = {
        Firewall = "nftables";
        DefaultDuration = "15m";
        DefaultAction = "deny";
        ProcMonitorMethod = "ebpf";
      };
      # /var/lib/opensnitch/rules/*
      rules =
        let
          bypassBwrap = pkg: pkg.passthru.noBwrap;
        in
        with pkgs; {
          loopback_ipv4 = lib.snitchAllowIp "127.0.0.1";
          loopback_ipv6 = lib.snitchAllowIp "::1";
          clamav-freshclam = lib.snitchAllowHost "database.clamav.net";
          nix = lib.snitchAllowPath "${nixFlakes}/bin/nix";
          network-manager = lib.snitchAllowPath "${networkmanager}/bin/NetworkManager";
          systemd-timesyncd = lib.snitchAllowPath "${systemd}/lib/systemd/systemd-timesyncd";
          firefox = lib.snitchAllowPath "${bypassBwrap firefox}/lib/firefox/firefox";
          dnscrypt-proxy = lib.snitchAllowPath "${dnscrypt-proxy2}/bin/dnscrypt-proxy";
          telegram = lib.snitchAllowPath "${bypassBwrap tdesktop}/bin/.telegram-desktop-wrapped";
          discord = lib.snitchAllowPath "${bypassBwrap discord}/opt/Discord/.Discord-wrapped";
          thunderbird = lib.snitchAllowPath "${bypassBwrap thunderbird}/lib/thunderbird/thunderbird";
          #chromium = lib.snitchAllowPath "${bypassBwrap chromium}/libexec/chromium/chromium";
          # Steam/steamapps/common/Proton 7.0/dist/bin/wineserver
          # Steam/steamapps/common/Proton - Experimental/files/bin/wine64-preloader
          # SteamLibrary/steamapps/common/Proton 8.0/dist/bin/wine64-preloader
          proton = lib.snitchRule { action = "allow"; name = "proton"; type = "regexp"; data = "^.*\/steamapps\/common\/Proton [^\/]*\/[^\/]*\/bin\/wine[^\/]*$"; };
          # /Steam/ubuntu12_32/steam
          # /Steam/ubuntu12_64/steamwebhelper
          steam = lib.snitchRule { action = "allow"; name = "steam"; type = "regexp"; data = ".*\/Steam\/ubuntu[^\/]*\/steam[^\/]*$"; };
          # Does not trully impact in anything, and after disabling dnscrypt [1]
          # it does not look that it is bypassing it, but just to be safe...
          # [1] - sudo pkill -STOP dnscrypt-proxy
          #     - sudo pkill -CONT dnscrypt-proxy
          nscd = lib.snitchDenyPath "${glibc}/bin/nscd";
          nsncd = lib.snitchAllowPath "${nsncd}/bin/nsncd";
          # file picker uses gvfs to send broadcast requests (192.168.1.255)
          gvfs = lib.snitchRule { action = "deny"; name = "gvfs"; type = "regexp"; data = "\/nix\/store\/[^\/]*\/libexec\/.gvfsd[^\/]*"; };
          zettlr-beta = lib.snitchRule { action = "deny"; name = "zettlr"; type = "regexp"; data = ".*-extracted/Zettlr$"; };
        };
    };
  };

  environment.systemPackages = with pkgs; [
    opensnitch-ui
  ];

  # does not have access to the network as specified bellow
  # by systemd.services
  services.nscd.enableNsncd = true;

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

  users.extraGroups.networkmanager.members = [ config.myNixOS.mainUser ];

  # FIXES: failed to sufficiently increase receive buffer size (from dnscrypt-proxy2.service)
  # https://github.com/quic-go/quic-go/wiki/UDP-Receive-Buffer-Size
  boot.kernel.sysctl."net.core.rmem_max" = 2500000; # default 212992

  services = {
    resolved.enable = false;

    dnscrypt-proxy2 = {
      enable = true;
      # Use defaults from: https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
      upstreamDefaults = true;
      settings = {
        log_file = "/var/log/dnscrypt-proxy/dnscrypt-proxy.log";
        log_file_latest = true;

        ipv6_servers = true;
        dnscrypt_servers = true;
        doh_servers = true;

        require_dnssec = true;
        require_nolog = true;
        require_nofilter = true;

        # Load-balancing: top 6, update ping over time
        lb_strategy = "p6";
        lb_estimator = true;

        # Enable support for HTTP/3 (DoH3, HTTP over QUIC)
        # Note that, like DNSCrypt but unlike other HTTP versions, this uses
        # UDP and (usually) port 443 instead of TCP.
        http3 = true;

        # DNSCrypt: Create a new, unique key for every single DNS query
        # This may improve privacy but can also have a significant impact on CPU usage
        # Only enable if you don't have a lot of network load
        dnscrypt_ephemeral_keys = true;

        # Cache
        # https://00f.net/2019/11/03/stop-using-low-dns-ttls/
        cache = true;
        cache_size = 8192;
        cache_min_ttl = 86400; # 1 day
        cache_max_ttl = 86400; # 1 day
        #cache_max_ttl = 604800; # 7 days
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
