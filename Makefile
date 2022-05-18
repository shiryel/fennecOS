.PHONY: flake_shiryel
flake_shiryel:
	sudo nixos-rebuild switch --flake '.#desktop'

.PHONY: flake_shiryel_upgrade
flake_shiryel_upgrade:
	sudo nixos-rebuild switch --flake '.#desktop' --upgrade

.PHONY: config
config:
	sh './scripts/install.sh'
