{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNixOS.desktopEnvironment.sway;
in
{
  options.myNixOS.desktopEnvironment.sway = {
    enable = mkEnableOption "Sway with a complete desktop environment";
  };

  config = mkIf cfg.enable {
    # Fix swaylock not unlocking:
    # https://github.com/nix-community/home-manager/issues/2017
    security.pam.services.swaylock = { };

    environment.systemPackages = with pkgs; [
      # This is pretty much the same as /etc/sway/config.d/nixos.conf [1] but also restarts  
      # some user services [2] to make sure they have the correct environment variables [3]
      # [1] - https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/applications/window-managers/sway/wrapper.nix#L20
      # [2] - https://wiki.archlinux.org/title/systemd/User#Environment_variables
      # [3] - https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
      (pkgs.writeScriptBin "sway-configure-dbus" ''
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
        systemctl --user restart pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
      ''
      )

      xwaylandvideobridge
      swaybg
      swaylock
      waybar
      wofi # menu
      wf-recorder
      wl-clipboard
      grim # screenshot
      slurp # select region for screenshot
      libnotify # required to use notify-send
      imv
      glfw-wayland # to make native games work
    ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    myHM.toMainUser = {
      xdg.configFile."sway/lockscreen".source = ../../imgs/lockscreen.png;
      xdg.configFile."sway/wallpaper".source = ../../imgs/wallpaper-hax.jpg;
      xdg.configFile."sway/config".text =
        let
          #out_left = "DP-1";
          #out_mid = "HDMI-A-1";
          #out_right = "HDMI-A-2";
          out_vr = "DP-2";

          out_left = "HDMI-A-1";
          out_mid = "DP-1";
          out_right = "HDMI-A-2";

          sway_session_init = (pkgs.writeScriptBin "sway-session-init" (builtins.readFile ./session.sh));
        in
        ''
          ##########
          # BASICS #
          ##########

          set $mod Mod4

          # Font for window titles. Will also be used by the bar unless a 
          font monospace 8.000000
          floating_modifier $mod

          bar {
            font monospace 8.000000
            swaybar_command waybar
          }

          #########
          # STYLE #
          #########

          # Theme colors
          # (Kanagawa Colorscheme: https://github.com/rebelot/kanagawa.nvim)
          # class                   border    backgr. text    indic.    child_border
          client.focused            #957FB8   #1F1F28 #DCD7BA #957FB8   #957FB8
          client.focused_inactive   #FFFFFF00 #1F1F28 #727169 #FFFFFF00 #FFFFFF00
          client.unfocused          #FFFFFF00 #1F1F28 #727169 #FFFFFF00 #FFFFFF00
          client.urgent             #FF5D62   #363646 #E46876 #FF5D62   #FF5D62
          client.placeholder        #000000   #0c0c0c #ffffff #000000   #0c0c0c
          client.background         #1F1F28

          ##########
          # DESIGN #
          ##########

          gaps inner 4
          gaps outer 0
          gaps top 0

          # Border style <normal|1pixel|pixel xx|none|pixel>
          default_border pixel 1
          default_floating_border pixel 2
          hide_edge_borders none

          #############
          # WORKSPACE #
          #############

          focus_wrapping no
          focus_follows_mouse yes
          focus_on_window_activation smart
          mouse_warping output
          workspace_layout default
          workspace_auto_back_and_forth yes

          workspace "1" output "${out_mid}"
          workspace "3" output "${out_mid}"
          workspace "5" output "${out_mid}"
          workspace "7" output "${out_mid}"
          workspace "9" output "${out_mid}"
          workspace "2" output "${out_right}"
          workspace "4" output "${out_right}"
          workspace "6" output "${out_right}"
          workspace "8" output "${out_right}"
          workspace "10" output "${out_right}"
          workspace "watch" output "${out_right}"
          workspace "11:" output "${out_mid}"
          workspace "12:" output "${out_right}"
          workspace "13:d" output "${out_left}"
          workspace "vr" output "${out_vr}"
          
          ############
          # BINDINGS #
          ############

          mode "disabled" {
            bindsym $mod+Shift+d mode default
          }

          mode "resize" {
            bindsym $mod+Down resize grow height 10px
            bindsym $mod+Left resize shrink width 10px
            bindsym $mod+Right resize grow width 10px
            bindsym $mod+Up resize shrink height 10px

            # return to default mode
            bindsym $mod+Escape mode default
            bindsym $mod+Return mode default
          }

          bindsym $mod+0 workspace 10
          bindsym $mod+1 workspace 1
          bindsym $mod+2 workspace 2
          bindsym $mod+3 workspace 3
          bindsym $mod+4 workspace 4
          bindsym $mod+5 workspace 5
          bindsym $mod+6 workspace 6
          bindsym $mod+7 workspace 7
          bindsym $mod+8 workspace 8
          bindsym $mod+9 workspace 9

          bindsym $mod+Shift+0 move container to workspace 10
          bindsym $mod+Shift+1 move container to workspace 1
          bindsym $mod+Shift+2 move container to workspace 2
          bindsym $mod+Shift+3 move container to workspace 3
          bindsym $mod+Shift+4 move container to workspace 4
          bindsym $mod+Shift+5 move container to workspace 5
          bindsym $mod+Shift+6 move container to workspace 6
          bindsym $mod+Shift+7 move container to workspace 7
          bindsym $mod+Shift+8 move container to workspace 8
          bindsym $mod+Shift+9 move container to workspace 9
          bindsym $mod+Ctrl+0 move container to workspace vr
          bindsym $mod+Ctrl+1 workspace 11:
          bindsym $mod+Ctrl+2 workspace 12:
          bindsym $mod+Ctrl+3 workspace 13:d

          # common - 1/top
          bindsym $mod+Shift+q kill
          bindsym $mod+Shift+d mode disabled
          bindsym $mod+d exec ${pkgs.zsh}/bin/zsh -ic '${pkgs.wofi}/bin/wofi --show drun,run | xargs swaymsg exec --'
          bindsym $mod+Shift+r reload; output ${out_left} transform 270
          bindsym $mod+Return exec ${pkgs.foot}/bin/foot

          # Layout stuff - 1/mid (Working with the focused windows)
          # You can "split" the current object of your focus with
          bindsym $mod+a splith
          bindsym $mod+s splitv
          bindsym $mod+h layout toggle split
          bindsym $mod+Shift+h mode resize
          bindsym $mod+t layout tabbed
          #bindsym $mod+g layout stacking

          # window toggles - 1/bottom
          bindsym $mod+z fullscreen
          bindsym $mod+x floating toggle
          bindsym $mod+m focus mode_toggle
          bindsym $mod+v focus parent

          # dangerous - 2/bottom
          bindsym $mod+Shift+k exec swaynag -t warning -m 'Power Menu Options' -b 'Logout' 'swaymsg exit' -b 'Restart' 'shutdown -r now' -b 'Shutdown'  'shutdown -h now' --background=#002b33DD --button-background=#0077b3DD --button-text=#FFFFFF --button-border-size=0 --text=#FFFFFF --border-bottom-size=0 --button-margin-right=10
          bindsym $mod+Shift+l exec '${pkgs.swaylock}/bin/swaylock -f -i ~/.config/sway/lockscreen'

          # Gaming - 2/top
          # see with: swaymsg -t get_outputs
          # man 5 sway-input
          #$mod+Shift+j input 1241:64605:USB_Gaming_Mouse map_to_region 1080 1400 1920 1080
          #$mod+Shift+f input 1241:64605:USB_Gaming_Mouse map_to_region 0 0 4920 2480
          # fix wine not finding mouse https://github.com/swaywm/sway/issues/4857
          # maybe its necessary to turn off monitors
          #$mod+Shift+u ${out_mid} resolution 1920x1080 position 0 0; output $out-left position 4920 1400

          # Misc - 2/top
          # screenshot
          bindsym $mod+p exec ${pkgs.grim}/bin/grim -t png -l 9 -o $(swaymsg -t get_outputs -r | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name') - > ~/Downloads/screenshot.png && ${pkgs.libnotify}/bin/notify-send -t 1000 "screenshot saved on ~/Downloads"

          # Moving around - 2/mid

          # Move your focus around
          bindsym $mod+Left focus left
          bindsym $mod+Down focus down
          bindsym $mod+Up focus up
          bindsym $mod+Right focus right
          bindsym $mod+n focus left
          bindsym $mod+e focus down
          bindsym $mod+o focus up
          bindsym $mod+i focus right

          # Move the focused window
          bindsym $mod+Shift+Left move left
          bindsym $mod+Shift+Down move down
          bindsym $mod+Shift+Up move up
          bindsym $mod+Shift+Right move right
          bindsym $mod+Shift+n move left
          bindsym $mod+Shift+e move down
          bindsym $mod+Shift+o move up
          bindsym $mod+Shift+i move right

          # Move to scratchpad
          # Sway has a "scratchpad", which is a bag of holding for windows.
          # You can send windows there and get them back later.
          bindsym $mod+y move scratchpad
          # Show the next scratchpad window or hide the focused scratchpad window.
          # If there are multiple scratchpad windows, this command cycles through them.
          bindsym $mod+Shift+y scratchpad show

          ##########
          # INPUTS #
          ##########

          # Huion Tablet (sometimes it has _Pen, sometimes it don't)
          input "9580:109:HUION_Huion_Tablet_HS611" {
            map_to_output ${out_mid}
          }
          input "9580:109:HUION_Huion_Tablet_HS611_Pad" {
            map_to_output ${out_mid}
          }
          input "9580:109:HUION_Huion_Tablet_HS611_Pen" {
            map_to_output ${out_mid}
          }

          input "type:keyboard" {
            xkb_layout us
            xkb_variant intl

            # to switch to the 3 level
            xkb_options lv3:ralt_switch

            #repeat_rate 50
            #repeat_delay 150
          }

          input "type:mouse" {
            accel_profile flat
            pointer_accel 1
          }

          input "type:touchpad" {
            tap enabled
            pointer_accel 1
          }

          ############
          # CRITERIA #
          ############
          #
          # To find about the apps ids:
          # swaymsg -t get_tree

          # show if window is running on xwayland
          for_window [shell=".*"] title_format "%title :: %shell"

          for_window [app_id="^(?!firefox)" title="^(?:Open|Save|Create) .*$"] floating enable
          for_window [class="opensnitch-ui"] floating enable
          for_window [class="opensnitch-ui"] resize set 900 700
          for_window [app_id="pavucontrol"] floating enable
          for_window [app_id="pavucontrol"] resize set 900 700
          for_window [app_id="thunderbird"] floating enable
          for_window [app_id="thunderbird" title="- Mozilla Thunderbird$"] floating disable
          for_window [app_id="org.kde.polkit-kde-authentication-agent-1"] floating enable
          for_window [instance="Godot_Engine"] floating enable

          # only works on xorg apps:
          for_window [window_role="app"] floating enable
          for_window [window_role="pop-up"] floating enable
          for_window [window_role="task_dialog"] floating enable
          for_window [window_role="bubble"] floating enable
          for_window [window_role="Preferences"] floating enable

          for_window [window_type="dialog"] floating enable
          for_window [window_type="menu"] floating enable

          # special assign for developing games in Rust Bevy
          assign [class="^game$"] watch

          ###########
          # STARTUP #
          ###########

          #exec sway-configure-dbus

          # Network
          exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator

          # Rotations and Positions
          exec_always swaymsg 'output ${out_left} position 0 0'
          exec_always swaymsg 'output ${out_left} transform 270'
          exec_always swaymsg 'output ${out_left} mode 1080x2560@60hz'
          # +1080 (when widescreen at 270)
          exec_always swaymsg 'output ${out_mid} position 1080 950'
          exec_always swaymsg 'output ${out_mid} mode 2560x1440@144hz'
          # +2560 (2k screen)
          exec_always swaymsg 'output ${out_right} position 3640 1280'
          # +1920 (1k screen)
          exec_always swaymsg 'output ${out_vr} position 5560 0'

          # xrandr set (to make games work on correct display)
          exec_always ${pkgs.xorg.xrandr}/bin/xrandr --output ${out_mid} --primary

          # Programs
          exec ${pkgs.mako}/bin/mako
          exec ${pkgs.swaybg}/bin/swaybg -i ~/.config/sway/wallpaper -m fill
          # swaymsg sets the mouse in the right place ;)
          exec swaymsg 'workspace 11:; exec firefox'
          # exec telegram if 2 monitors
          exec swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -e '.[1]' && swaymsg 'workspace 12:; exec ${pkgs.tdesktop}/bin/telegram-desktop'
          # exec discord if 3 monitors
          exec swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -e '.[2]' && swaymsg 'workspace 13:d; exec "${pkgs.foot}/bin/foot -e ${pkgs.btop}/bin/btop"; layout toggle split; exec ${pkgs.discord}/bin/discord'

          # RENDER TIME ADJUSTEMENTS
          # Change this if you get stutters
          # https://artemis.sh/2022/09/18/wayland-from-an-x-apologist.html
          # https://www.reddit.com/r/swaywm/comments/jfjsqy/comment/gh8xgjq/?context=3
          # https://www.reddit.com/r/swaywm/comments/rettyx/please_help_me_understand_how_to_use_max_render/
          #
          # set render time to 8ms for all windows
          # calc: 60 fps = 1/60 * 1000 = 16.6ms
          exec swaymsg 'for_window [title=.*] max_render_time 17'
          exec swaymsg 'output * max_render_time 17'
          #exec swaymsg 'output * adaptive_sync on'

          # start systemd sway-session target
          #exec "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL; systemctl --user start sway-session.target"
          exec ${sway_session_init}/bin/sway-session-init
        '';
    };
  };
}
