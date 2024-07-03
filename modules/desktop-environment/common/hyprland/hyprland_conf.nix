{ lib, pkgs, ... }:
let
  mod = "SUPER";
  out_vr = "DP-2";
  out_left = "HDMI-A-1";
  out_mid = "DP-1";
  out_right = "HDMI-A-2";
  menu = ''
    ${pkgs.procps}/bin/pkill wofi || ${pkgs.wofi}/bin/wofi --show drun,run | ${pkgs.findutils}/bin/xargs ${pkgs.hyprland}/bin/hyprctl keyword exec --
  '';
  terminal = "${pkgs.foot}/bin/foot";
  #lock = "${pkgs.hyprlock}/bin/hyprlock --immediate";
  lock = "${pkgs.swaylock}/bin/swaylock -f -i ~/.config/hypr/lockscreen";
  printclip = "${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy";
  printscreen = ''${pkgs.grim}/bin/grim -t png -l 9 -o $(swaymsg -t get_outputs -r | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name') - > ~/Downloads/screenshot.png && ${pkgs.libnotify}/bin/notify-send -t 1000 "screenshot saved on ~/Downloads'';
  target = "${pkgs.systemd}/bin/systemctl --user start hyprland-session.target";
in
pkgs.writeTextFile {
  name = "hyprland-config";
  text = ''
    # See: https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

    # You can split this configuration into multiple files
    # Create your files separately and then link them to this file like this:
    # source = ~/.config/hypr/myColors.conf

    ############
    # MONITORS #
    ############

    # See https://wiki.hyprland.org/Configuring/Monitors/

    # Transform list:
    # normal (no transforms) -> 0
    # 90 degrees -> 1
    # 180 degrees -> 2
    # 270 degrees -> 3
    # flipped -> 4
    # flipped + 90 degrees -> 5
    # flipped + 180 degrees -> 6
    # flipped + 270 degrees -> 7
    monitor=${out_left},preferred,0x0,auto,transform,1
    #monitor=${out_mid},2560x1440@144,1080x950,auto, vrr,2
    monitor=${out_mid},2560x1440,1080x950,auto
    monitor=${out_right},preferred,3640x1280,auto
    monitor=${out_vr},preferred,5560x0,auto

    #############
    # AUTOSTART #
    #############

    # Autostart necessary processes (like notifications daemons, status bars, etc.)
    # Or execute your favorite apps at launch like this:

    exec-once = ${target}
    exec-once = ${pkgs.waybar}/bin/waybar &
    exec-once = ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator &

    #################
    # LOOK AND FEEL #
    #################
    # See: https://wiki.hyprland.org/Configuring/Variables/

    # https://wiki.hyprland.org/Configuring/Variables/#general
    general { 
      gaps_in = 4
      gaps_out = 10

      border_size = 2

      # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
      col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
      col.inactive_border = rgba(595959aa)

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false 

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = false

      layout = dwindle
    }

    # https://wiki.hyprland.org/Configuring/Variables/#decoration
    decoration {
      rounding = 10

      # Change transparency of focused and unfocused windows
      active_opacity = 1.0
      inactive_opacity = 1.0

      drop_shadow = true
      shadow_range = 4
      shadow_render_power = 3
      col.shadow = rgba(1a1a1aee)

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur {
        enabled = true
        size = 3
        passes = 1
      
        vibrancy = 0.1696
      }
    }

    # https://wiki.hyprland.org/Configuring/Variables/#animations
    animations {
      enabled = true

      # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

      bezier = myBezier, 0.05, 0.9, 0.1, 1.05

      animation = windows, 1, 7, myBezier
      animation = windowsOut, 1, 7, default, popin 80%
      animation = border, 1, 10, default
      animation = borderangle, 1, 8, default
      animation = fade, 1, 7, default
      animation = workspaces, 1, 6, default
    }

    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    dwindle {
      pseudotile = true # Master switch for pseudotiling. Enabling is bound to {mod} + P in the keybinds section below
      preserve_split = true
    }

    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    master {
      new_is_master = true
    }

    # https://wiki.hyprland.org/Configuring/Variables/#misc
    misc { 
      force_default_wallpaper = 2 # Set to 0 or 1 to disable the anime mascot wallpapers
      disable_hyprland_logo = false # If true disables the random hyprland logo / anime girl background. :(
      #vrr = 2 # fullscreen only
      new_window_takes_over_fullscreen = 1
    }

    binds {
      #middle_click_paste = 0 # TODO
      workspace_back_and_forth = true
    }

    #########
    # INPUT #
    #########

    # https://wiki.hyprland.org/Configuring/Variables/#input
    input {
      kb_layout = us
      kb_variant = intl
      kb_model =
      kb_options = lv3:ralt_switch
      kb_rules =

      follow_mouse = 1
      #mouse_refocus = false # FIXES: https://github.com/hyprwm/Hyprland/issues/2376

      sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

      touchpad {
        natural_scroll = false
      }

      tablet {
        output = ${out_mid}
      }
    }

    # https://wiki.hyprland.org/Configuring/Variables/#gestures
    gestures {
      workspace_swipe = false
    }

    # Example per-device config
    # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
    #device {
    #  name = epic-mouse-v1
    #  sensitivity = -0.5
    #}

    ##############
    # WORKSPACES #
    ##############

    workspace = 1, monitor:${out_mid}
    workspace = 3, monitor:${out_mid}
    workspace = 5, monitor:${out_mid}
    workspace = 7, monitor:${out_mid}
    workspace = 9, monitor:${out_mid}
    workspace = 2, monitor:${out_right}
    workspace = 4, monitor:${out_right}
    workspace = 6, monitor:${out_right}
    workspace = 8, monitor:${out_right}
    workspace = 10, monitor:${out_right}
    workspace = 11, name:, monitor:${out_mid}, persistent:true, default:true, on-created-empty:[tile] ${pkgs.firefox}/bin/firefox
    workspace = 12, name:, monitor:${out_right}, persistent:true, default:true, on-created-empty:[tile] sleep 1 & ${pkgs.tdesktop}/bin/telegram-desktop
    workspace = 13, name:, monitor:${out_left}, persistent:true, default:true, on-created-empty:[tile] ${pkgs.foot}/bin/foot -e "${pkgs.btop}/bin/btop" & ${pkgs.discord}/bin/discord
    workspace = 14, name:, monitor:${out_vr}, default:true
    workspace = 15, name:, monitor:${out_right}

    ################
    # KEYBINDINGSS #
    ################
    # See:
    # - https://wiki.hyprland.org/Configuring/Keywords/
    # - https://wiki.hyprland.org/Configuring/Binds/

    submap=disabled
      bind = ${mod} SHIFT, D, submap, reset
    submap=reset

    # common - 1/top
    bind = ${mod} SHIFT, Q, killactive
    bind = ${mod} SHIFT, D, submap, disabled
    bind = ${mod}, D, exec, ${menu}
    bind = ${mod} SHIFT, R, exec, hyprctl reload
    bind = ${mod}, RETURN, exec, ${terminal}

    # Layout stuff - 1/mid (Working with the focused windows)
    bind = ${mod}, A, togglesplit
    bind = ${mod}, S, swapsplit
    bind = ${mod}, H, togglegroup
    bind = ${mod}, T, changegroupactive, b
    bind = ${mod}, G, changegroupactive, f

    # window toggles - 1/bottom
    bind = ${mod}, Z, fullscreen
    bind = ${mod} SHIFT, Z, fakefullscreen
    bind = ${mod}, X, togglefloating
    bind = ${mod} SHIFT, X, pin
    bind = ${mod}, C, centerwindow
    #bind = ${mod} SHIFT, V, forceinput # Might fix issues like e.g. Game Launchers not receiving focus for some reason
    bind = ${mod}, V, exec, hyprctl keyword monitor ${out_mid},preferred,-10000x0,auto
    bind = ${mod} SHIFT, V, exec, hyprctl keyword monitor ${out_mid},preferred,1080x950,auto

    # Misc - 2/top
    bind = ${mod}, P, exec, ${printclip}
    bind = ${mod} SHIFT, P, exec, ${printscreen}

    # dangerous - 2/bottom
    bind = ${mod} SHIFT, L, exec, ${lock}

    # Moving around - 2/mid
    bind = ${mod}, left, movefocus, l
    bind = ${mod}, down, movefocus, d
    bind = ${mod}, up, movefocus, u
    bind = ${mod}, right, movefocus, r
    bind = ${mod}, n, movefocus, l
    bind = ${mod}, e, movefocus, d
    bind = ${mod}, o, movefocus, u
    bind = ${mod}, i, movefocus, r

    bind = ${mod} SHIFT, left, movewindoworgroup, l
    bind = ${mod} SHIFT, down, movewindoworgroup, d
    bind = ${mod} SHIFT, up, movewindoworgroup, u
    bind = ${mod} SHIFT, right, movewindoworgroup, r
    bind = ${mod} SHIFT, n, movewindoworgroup, l
    bind = ${mod} SHIFT, e, movewindoworgroup, d
    bind = ${mod} SHIFT, o, movewindoworgroup, u
    bind = ${mod} SHIFT, i, movewindoworgroup, r

    ##############
    # WORKSPACES #
    ##############

    # Move to scratchpad, a bag of holding for windows.
    # You can send windows there and get them back later.
    bind = ${mod}, Y, togglespecialworkspace, magic
    bind = ${mod} SHIFT, Y, movetoworkspace, special:magic

    # Switch workspaces with {mod} + [0-9]
    bind = ${mod}, 1, workspace, 1
    bind = ${mod}, 2, workspace, 2
    bind = ${mod}, 3, workspace, 3
    bind = ${mod}, 4, workspace, 4
    bind = ${mod}, 5, workspace, 5
    bind = ${mod}, 6, workspace, 6
    bind = ${mod}, 7, workspace, 7
    bind = ${mod}, 8, workspace, 8
    bind = ${mod}, 9, workspace, 9
    bind = ${mod}, 0, workspace, 10
    bind = ${mod} CTRL, 1, workspace, 11
    bind = ${mod} CTRL, 2, workspace, 12
    bind = ${mod} CTRL, 3, workspace, 13

    # Move active window to a workspace with {mod} + SHIFT + [0-9]
    bind = ${mod} SHIFT, 1, movetoworkspace, 1
    bind = ${mod} SHIFT, 2, movetoworkspace, 2
    bind = ${mod} SHIFT, 3, movetoworkspace, 3
    bind = ${mod} SHIFT, 4, movetoworkspace, 4
    bind = ${mod} SHIFT, 5, movetoworkspace, 5
    bind = ${mod} SHIFT, 6, movetoworkspace, 6
    bind = ${mod} SHIFT, 7, movetoworkspace, 7
    bind = ${mod} SHIFT, 8, movetoworkspace, 8
    bind = ${mod} SHIFT, 9, movetoworkspace, 9
    bind = ${mod} SHIFT, 0, movetoworkspace, 10
    bind = ${mod} CTRL, 0, movetoworkspace, 14

    # Scroll through existing workspaces with {mod} + scroll
    bind = ${mod}, mouse_down, workspace, e+1
    bind = ${mod}, mouse_up, workspace, e-1

    # Move/resize windows with {mod} + LMB/RMB and dragging
    bindm = ${mod}, mouse:272, movewindow
    bindm = ${mod}, mouse:273, resizewindow

    ################################
    # WINDOWS AND WORKSPACES RULES #
    ################################

    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

    # Example windowrule v1
    # windowrule = float, ^(kitty)$

    # Example windowrule v2
    # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

    windowrulev2 = float, class:opensnitch_ui # started manually
    windowrulev2 = center 1, class:opensnitch_ui # started manually
    windowrulev2 = float, class:opensnitch-ui # started from systemd
    windowrulev2 = center 1, class:opensnitch-ui # started from systemd

    # reduce latency and/or jitter in games
    #windowrulev2 = immediate, title:^(Team Fortress 2)(.*)$
    #windowrulev2 = immediate, class:^(cs2)$
    #windowrulev2 = immediate, class:^(.*)(\.exe)$
    #windowrulev2 = immediate, class:^(Minecraft.*)$

    windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.
  '';
}
