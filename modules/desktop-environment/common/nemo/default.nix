{ pkgs, ... }:

let

  nemo_action_extract = pkgs.writeText "nemo-action-extract" (builtins.readFile ./actions/extract_with_7z.nemo_action);
  nemo_action_window_overview = pkgs.writeText "nemo-action-window-overview" (builtins.readFile ./actions/window_overview.nemo_action);
  nemo_action_attach_to_email = pkgs.writeText "nemo-action-attach-to-email" (builtins.readFile ./actions/attach_to_email_tbird.nemo_action);

  nemo_action_script_extract = pkgs.writeScript "nemo-action-script-extract" ''
    #!/usr/bin/env bash
    for i in "$@"; do
      7z -y -o"$(echo $i | sed "s/\.[^.]*$//")" x "$(echo $i)"
    done
  '';
in
{
  # manually re-run with `systemd-tmpfiles --user --create --remove`

  # docs: https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action
  # examples: https://github.com/smurphos/nemo_actions_and_cinnamon_scripts
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/.local/share/nemo/actions/action_scripts/extract_with_7z 777 - - - ${nemo_action_script_extract}"

    "L+ %h/.local/share/nemo/actions/extract_with_7z.nemo_action 777 - - - ${nemo_action_extract}"
    "L+ %h/.local/share/nemo/actions/window_overview.nemo_action 777 - - - ${nemo_action_window_overview}"
    "L+ %h/.local/share/nemo/actions/attach_to_email_tbird.nemo_action 777 - - - ${nemo_action_attach_to_email}"
  ];

  environment.systemPackages = with pkgs; [
    # In case that the video previews are not working,
    # remove the fail/ on .cache/thumbnails/
    cinnamon.nemo
    libsForQt5.gwenview # images
    foliate # ebooks
    ffmpeg # (ranger, nautilus)
    ffmpegthumbnailer # (ranger, nautilus)
    p7zip
    # TODO:
    # gnome-epub-thumbnailer

    # /etc/profiles/per-user/shiryel/share/thumbnailers
    # /run/current-system/sw/share/thumbnailers
    (
      pkgs.writeTextFile {
        name = "thumbnailers";
        text = ''
          [Thumbnailer Entry]
          TryExec=${pkgs.p7zip}/bin/7z
          Exec=sh -c "${pkgs.p7zip}/bin/7z -so x %i preview.png > %o"
          MimeType=application/x-krita;
        '';
        destination = "/share/thumbnailers/kra.thumbnailer";
      }
    )
  ];

  #
  # Thumbnailers
  #
  # See: 
  # https://moritzmolch.com/blog/1749.html
  # https://docs.xfce.org/xfce/tumbler/available_plugins

  # $HOME/.local/share/thumbnailers
  #xdg.dataFile."thumbnailers/kra.thumbnailer".text = ''
  #  [Thumbnailer Entry]
  #  TryExec=7z
  #  Exec=sh -c "${pkgs.p7zip}/bin/7z x %i preview.png > %o"
  #  MimeType=application/x-krita;
  #'';

  #xdg.dataFile."thumbnailers/xcf.thumbnailer".text = ''
  #  [Thumbnailer Entry]
  #  TryExec=
  #  Exec=${pkgs.imagemagick}/bin/convert xcf:%i -flatten -scale 512x%s png:%o
  #  MimeType=image/x-xcf;
  #'';
}
