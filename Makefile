.PHONY: clean
clean:
	rm -f result

check:
	nix flake --extra-experimental-features "nix-command flakes" show .
	nix flake --extra-experimental-features "nix-command flakes" check . --show-trace

build-image:
	nix build --extra-experimental-features "nix-command flakes" --print-out-paths -L '.#nixosConfigurations.${machine}.config.system.build.image'

edit-secret:
	agenix -e secrets/${name}.age

remote-switch:
	nixos-rebuild switch --target-host ${machine} --build-host ${machine} --flake .#${machine} --use-remote-sudo