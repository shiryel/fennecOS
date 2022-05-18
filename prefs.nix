{ lib }:
{
  unfree_packages =
    (pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-run"
      "steam-original"
      "discord-canary"
      "postman"
      "corefonts"
      "tools"
      #"android-studio-canary"
    ]);

  steam = {
    vr_integration = false;
  };

  bwrap_binds = {
    common = [
      "~/downloads"
    ];

    docs = [
      "/keep/data/docs/work"
      "~/data/docs/work"
      "/keep/data/docs/books"
      "~/data/docs/books"
      "/keep/data/projects/drawings"
      "~/data/projects/drawings"
      "~/projects/drawings"
    ];

    code = [
      "/keep/data/projects"
      "~/data/projects"
      "~/projects"
    ];

    game = [
      "/keep/games"
    ];
  };

  colors = {
    ########################
    # Kanagawa Colorscheme #
    ########################
    # https://github.com/rebelot/kanagawa.nvim

    # Default foreground
    fuji_white = "#DCD7BA";
    # Dark foreground (statuslines)
    old_white = "#C8C093";
    # Dark background (statuslines and floating windows)
    sumi_ink_0 = "#16161D";
    # Default background
    sumi_ink_1 = "#1F1F28";
    # Lighter background (colorcolumn, folds)
    sumi_ink_2 = "#2A2A37";
    # Lighter background (cursorline)
    sumi_ink_3 = "#363646";
    # Darker foreground (line numbers, fold column, non-text characters), float borders
    sumi_ink_4 = "#54546D";
    # Popup background, visual selection background
    wave_blue_1 = "#223249";
    # Popup selection background, search background
    wave_blue_2 = "#2D4F67";
    # Diff Add (background)
    winter_green = "#2B3328";
    # Diff Change (background)
    winter_yellow = "#49443C";
    # Diff Deleted (background)
    winter_red = "#43242B";
    # Diff Line (background)
    winter_blue = "#252535";
    # Git Add
    autumn_green = "#76946A";
    # Git Delete
    autumn_red = "#C34043";
    # Git Change
    autumn_yellow = "#DCA561";
    # Diagnostic Error
    samurai_red = "#E82424";
    # Diagnostic Warning
    ronin_yellow = "#FF9E3B";
    # Diagnostic Info
    wave_aqua_1 = "#6A9589";
    # Diagnostic Hint
    dragon_blue = "#658594";
    # Comments
    fuji_gray = "#727169";
    # Light foreground
    spring_violet_1 = "#938AA9";
    # Statements and Keywords
    oni_violet = "#957FB8";
    # Functions and Titles
    crystal_blue = "#7E9CD8";
    # Brackets and punctuation
    spring_violet_2 = "#9CABCA";
    # Specials and builtin functions
    spring_blue = "#7FB4CA";
    # Not used
    light_blue = "#A3D4D5";
    # Types
    wave_aqua_2 = "#7AA89F";
    # Strings
    spring_green = "#98BB6C";
    # Not used
    boat_yellow_1 = "#938056";
    # Operators, RegEx
    boat_yellow_2 = "#C0A36E";
    # Identifiers
    carp_yellow = "#E6C384";
    # Numbers
    sakura_pink = "#D27E99";
    # Standout specials 1 (builtin variables)
    wave_red = "#E46876";
    # Standout specials 2 (exception handling, return)
    peach_red = "#FF5D62";
    # Constants, imports, booleans
    surimi_orange = "#FFA066";
    # Deprecated
    katana_gray = "#717C7C";
  };
}
