{ lib, pkgs, ... }:

{
  services.dbus.apparmor = "enabled";
  #boot.tmp.cleanOnBoot = true;

  # Trimming enables the SSD to more efficiently handle garbage collection,
  # which would otherwise slow future write operations to the involved blocks.
  services.fstrim.enable = true;

  # xdg's autostart is unecessary
  xdg.autostart.enable = lib.mkForce false;

  # antivirus clamav and keep the signatures' database updated
  # see: https://github.com/anoadragon453/dotfiles/blob/de37bcd64f702b16115fb405f559e979a1e0260e/modules/base/antivirus.nix#L69
  services = {
    clamav.daemon.enable = true;
    clamav.updater.enable = true;
  };

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
    openFirewall = lib.mkForce false;
    startWhenNeeded = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = lib.mkForce false;
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
