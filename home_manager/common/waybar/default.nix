{ lib, pkgs, pkgs_unstable, ... }@inputs:

{
  wayland.windowManager.sway.config.bars = [
    { command = "waybar"; }
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = false;
    style = builtins.readFile ./waybar.css;
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];
      modules-center = [ "clock" "idle_inhibitor" ];
      modules-right = [ "pulseaudio" "network" "temperature" "cpu" "memory" "battery" "tray" ];
      "sway/workspaces" = {
        all-outputs = false;
        disable-scroll = false;
        enable-bar-scroll = true;
        disable-scroll-wraparonud = true;
        smooth-scrolling-threshold = 1;
        format = "{name} {icon}";
        format-icons = {
          urgent = "";
          default = "";
        };
      };

      "sway/mode" = {
        format =
          ''<span style="italic"> {}</span>''; # Icon: expand-arrows-alt;
        tooltip = false;
      };

      clock = {
        interval = 1;
        format = "{:%a %e %b - %H:%M}";
        tooltip = false;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
      };

      pulseaudio = {
        scroll-step = 1;
        format = "{icon}  {volume}%";
        format-bluetooth = " {icon}  {volume}% ";
        format-muted = "🔇";
        format-icons = rec {
          headphones = "";
          handsfree = headphones;
          headset = headphones;
          phone = "";
          portable = "";
          car = " ";
          default = [ "奄" "奔" "墳" ];
        };
        on-click = "pavucontrol";
      };

      network = {
        interval = 5;
        format-wifi = "直{essid}";
        format-ethernet = "歷 {ifname}";
        format-disconnected = "睊Disconnected";
        tooltip-format = "{ifname}: {ipaddr}/{cidr} {signalStrength}%";
      };

      temperature = {
        thermal-zone = 2;
        # CPU Temp: "/sys/class/hwmon/hwmon*/temp1_input"
        # GPU Temp: "/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input"
        hwmon-path = "/sys/class/drm/card0/device/hwmon/hwmon0/temp1_input";
        critical-threshold = 85;
        format-critical = " {temperatureC}°C ";
        format = " {temperatureC}°C ";
      };

      cpu = {
        interval = 5;
        format = " {load} / {usage}%"; # Icon: microchip;
        states = {
          warning = 70;
          critical = 90;
        };
      };

      memory = {
        interval = 3;
        format = " {}%";
      };

      battery = rec {
        interval = 1;
        states = {
          warning = 35;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-plugged = "" + format;
        format-charging = format-plugged;
        format-icons = [ "" "" "" "" "" "" "" "" "" "" ];
      };

      tray = {
        icon-size = 17;
        spacing = 10;
        show-passive-items = true;
      };
    }];
  };
}
