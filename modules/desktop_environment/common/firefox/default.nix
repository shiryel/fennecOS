{ lib, pkgs, ... }:

with lib;

let
  user_js = attrs:
    ''
      ${builtins.readFile ./arkenfox.js}

      ${concatStrings (mapAttrsToList (n: v: ''
        user_pref("${n}", ${builtins.toJSON v});
      '') attrs)}
    '';

  firefox_path = "bwrap/mozilla/firefox";
  profile_path = "hnvepnot.default";

  firefox_profiles = pkgs.writeText "firefox-profiles" (lib.generators.toINI { } {
    Profile0 = {
      Name = "default";
      IsRelative = 1;
      Path = profile_path;
      Default = 1;
    };
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };
  });

  firefox_user_js = pkgs.writeText "firefox-user-js" (
    user_js {
      # Prefferences
      "browser.sessionstore.restore_on_demand" = true;
      "browser.shell.checkDefaultBrowser" = false;
      "extensions.pocket.enabled" = false;
      "geo.enabled" = false; # do not even let them even ask it
      "findbar.highlightAll" = true; # find highlight all by default
      "ui.prefersReducedMotion" = true; # disable chrome animations
      "privacy.webrtc.legacyGlobalIndicator" = false; # hide WebRTC microphone/camera access indicator
      "keyword.enabled" = true; # enable search from location bar
      "devtools.toolbox.host" = "right";
      "privacy.resistFingerprinting.letterboxing" = false; # disable window dimension RFP

      # Keep after shutdown
      "browser.startup.page" = 3; # Resume previous session
      "browser.cache.disk.enable" = true; # Keep cache
      "privacy.sanitize.sanitizeOnShutdown" = false; # possible impacts the options bellow
      "privacy.clearOnShutdown.cache" = false;
      "privacy.clearOnShutdown.openWindows" = false;
      "privacy.clearOnShutdown.cookies" = false;
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.sessions" = false;
      "privacy.clearOnShutdown.offlineApps" = false; # site data

      # Don't allow websites to prevent copy and paste.
      # Disable notifications of copy, paste, or cut functions. 
      # Stop webpage knowing which part of the page had been selected.
      #"dom.event.clipboardevents.enabled" = false;

      #
      # Performance
      #

      # Enable Hardware Acceleration and Off Main Thread Compositing (OMTC).
      # It's likely your browser is already set to use these features.
      # May introduce instability on some hardware.
      "webgl.disabled" = false;
      "layers.acceleration.force-enabled" = true;
      "html5.offmainthread" = true;

      # enables using the Wayland compositor directly to compose each frame
      "gfx.webrender.compositor" = true;
      "gfx.webrender.compositor.force-enabled" = true;

      #
      # Privacy
      #

      "privacy.trackingprotection.enabled" = true; # Mozilla’s built in protections
      "privacy.resistFingerprinting" = true; # Mozilla’s built in protections
      "browser.send_pings" = false; # Prevent website tracking clicks
      "dom.battery.enabled" = false; # Disable website reading how much battery your mobile device or laptop has
      "toolkit.telemetry.cachedClientID" = ""; # Mozilla's telemetry
      "network.trr.mode" = 5; # To turn off Firefox's new "partnership" with Cloudflare
      "clipboard.autocopy" = false; # disable mouse middle click clipboard
      "dom.private-attribution.submission.enabled" = false; # don't send data to Mozilla

      # Tells website where you came from. Disabling may break some sites.
      # 0 = Disable referrer headers, 1 = Send only on clicked links, 2 = (default) Send for links and image.
      # NOTE: Needs 2 to work with many sites
      "network.http.sendRefererHeader" = 2;
      # control when to send a cross-origin referer
      # 0=always (default), 1=only if base domains match, 2=only if hosts match
      # NOTE: Needs 0 to work with many sites
      "network.http.referer.XOriginPolicy" = 0;
      # Send fake referrer (if choose to send referrers)
      "network.http.referer.spoofSource" = true;

      # Disable cookies.
      # 0 = All cookies are allowed. (Default) 
      # 1 = Only cookies from the originating server are allowed. (block third party cookies)
      # 2 = No cookies are allowed. 
      # 3 = Third-party cookies are allowed only if that site has stored cookies already from a previous visit 
      # 4 = Only reject trackers (Storage partitioning disabled).
      # 5 = Reject (known) trackers and partition third-party storage.
      "network.cookie.cookieBehavior" = 5;
      "network.cookie.cookieBehavior.pbmode" = 1;

      # Disable "personality-provider"
      "browser.newtabpage.activity-stream.discoverystream.personalization.enabled" = false;

      # https://support.mozilla.org/en-US/kb/how-does-phishing-and-malware-protection-work?as=u&utm_source=inproduct
      # "Firefox will submit some information about the file, including the name, origin, size and a cryptographic hash of the contents, to the Google Safe Browsing service"
      #"browser.safebrowsing.malware.enabled" = false;
      #"browser.safebrowsing.downloads.enabled" = false;
      "browser.safebrowsing.downloads.remote.enabled" = false;

      # Brilliant idea: https://www.reddit.com/r/web_design/comments/hr59z/comment/c1xo6pf/?utm_source=share&utm_medium=web2x&context=3
      # https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome
      # NOTE: https://bugzilla.mozilla.org/show_bug.cgi?id=1489903#c12
      # general.useragent.override = "Mozilla/2.0 (compatible; MSIE 3.03; Windows 3.1)";
    }
  );
in
{
  systemd.user.tmpfiles.users.shiryel.rules = [
    "L+ %h/${firefox_path}/profiles.ini 777 - - - ${firefox_profiles}"
    "L+ %h/${firefox_path}/${profile_path}/user.js 777 - - - ${firefox_user_js}"
  ];
}
