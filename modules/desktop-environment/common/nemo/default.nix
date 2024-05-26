{ pkgs, ... }:

{
  myHM.toMainUser = {
    home.packages = with pkgs; [
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
    ];

    # docs: https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action
    # examples: https://github.com/smurphos/nemo_actions_and_cinnamon_scripts
    # ~/.local/share/
    xdg.dataFile."nemo/actions/" = {
      source = ./actions;
      recursive = true;
    };

    xdg.dataFile."nemo/actions/action_scripts/extract_with_7z" = {
      text = ''
        #!/usr/bin/env bash
        for i in "$@"; do
          7z -y -o"$(echo $i | sed "s/\.[^.]*$//")" x "$(echo $i)"
        done
      '';
      executable = true;
    };

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
  };

  # /etc/profiles/per-user/shiryel/share/thumbnailers
  # /run/current-system/sw/share/thumbnailers
  environment.systemPackages = [
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
}
