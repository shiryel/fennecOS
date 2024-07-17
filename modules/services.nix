{ lib, pkgs, ... }:

{
  #########
  # Extra #
  #########

  programs.ccache.enable = true;
  environment.wordlist.enable = true;

  #################
  # GENERAL FIXES #
  #################

  programs = {
    neovim.enable = false;
  };

  # Fixes android file transfer, nautilus and 
  # https://wiki.archlinux.org/title/Java#Java_applications_cannot_open_external_links
  #services.gvfs.enable = true;

  # lets android devices connect
  services.udev.packages = [ pkgs.android-udev-rules ];
  users.groups.adbusers = { }; # To enable device as a user device if found (add an "android" SYMLINK)

  #########
  # AUDIO #
  #########

  # https://nixos.wiki/wiki/PipeWire
  # Use `pw-profiler` to profile audio and `pw-top`
  # to see the outputs and quantum/rate
  # quantum/rate*1000 = ms delay
  # eg: 3600/48000*1000 = 75ms
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  ############
  # SECURITY #
  ############

  security.sudo.execWheelOnly = false; # btrbk needs this false to work

  # test with: sudo apparmor_status
  security.apparmor.enable = true;

  services.dbus = {
    apparmor = "enabled";
    implementation = "broker"; # dbus-broker is the default on Arch & Fedora
  };

  security = {
    # RealtimeKit is optional but recommended
    # Hands out realtime scheduling priority to user processes on demand
    rtkit.enable = true; # NOTE: enables polkit!
  };

  # Trimming enables the SSD to more efficiently handle garbage collection,
  # which would otherwise slow future write operations to the involved blocks.
  services.fstrim.enable = true;

  # xdg's autostart is unecessary
  xdg.autostart.enable = lib.mkForce false;

  # antivirus clamav and keep the signatures' database updated
  # see: https://github.com/anoadragon453/dotfiles/blob/de37bcd64f702b16115fb405f559e979a1e0260e/modules/base/antivirus.nix#L69
  #services = {
  #  clamav.daemon.enable = true;
  #  clamav.updater.enable = true;
  #};

  #######
  # SSH #
  #######
  # NOTE: We use GNUPG agent instead of its own agent

  # SSH AGENT
  # NOTE:
  # home-manager automatically calls ssh-add for the ssh-agent with [1]
  # [1] - home.file.".ssh/config".text = "AddKeysToAgent yes";
  # You can set how it will ask with one of:
  # - environment.SSH_ASKPAS
  # - programs.ssh.askPassword & programs.ssh.enableAskPassword
  programs.ssh = {
    startAgent = false;
  };

  # SSH DAEMON (to do connections)
  services.openssh = {
    enable = true;
    allowSFTP = false;
    openFirewall = lib.mkForce false;
    startWhenNeeded = true;
    hostKeys = [ ]; # do not generate any host keys
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = lib.mkForce false;
      X11Forwarding = false;
      AllowAgentForwarding = "no";
      AllowStreamLocalForwarding = "no";
      AuthenticationMethods = "publickey";
    };
  };

  ###############
  # GNUPG AGENT #
  ###############

  # Generate GPG Keys With Curve Ed25519: https://www.digitalneanderthal.com/post/gpg/
  programs.gnupg.agent = {
    enable = true;
    # cache SSH keys added by the ssh-add
    enableSSHSupport = true;
    # set up a Unix domain socket forwarding from a remote system
    # enables to use gpg on the remote system without exposing the private keys to the remote system
    enableExtraSocket = false;
    # allows web browsers to access the gpg-agent daemon
    enableBrowserSocket = false;
    # NOTE: "gnome3" flavor only works with Xorg
    # To reload config: gpg-connect-agent reloadagent /bye
    pinentryPackage = pkgs.pinentry-gnome3; # use "pkgs.pinentry-curses" for console only
  };

  environment.systemPackages = [ pkgs.gnupg ];
}
