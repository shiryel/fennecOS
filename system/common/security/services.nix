{ lib, pkgs, pkgs_unstable, ... }:

{
  services.dbus.apparmor = "enabled";

  # xdg's autostart is unecessary
  xdg.autostart.enable = lib.mkForce false;

  # antivirus clamav and keep the signatures' database updated
  services = {
    #clamav.daemon.enable = true;
    #clamav.updater.enable = true;
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
    passwordAuthentication = lib.mkForce false;
    openFirewall = lib.mkForce false;
    permitRootLogin = lib.mkForce "no";
    startWhenNeeded = true;
  };

  ###############
  # GNUPG AGENT #
  ###############

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
    pinentryFlavor = "gtk2"; # use "tty" for console only
  };

  environment.systemPackages = [ pkgs.gnupg ];
}
