* nixosConfigurations are applied with `nixos-rebuild switch --flake .#<host> --target-host <host> --sudo`
* kubernets manifests are applied with ArgoCD so must be committed + pushed to origin/main