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
  };
}
