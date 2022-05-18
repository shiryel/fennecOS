{ lib, ... }:

final: prev: {
  discord = prev.discord.override {
    nss = prev.nss_latest;
  };

  discord-canary = prev.discord-canary.override {
    nss = prev.nss_latest;
  };
}
