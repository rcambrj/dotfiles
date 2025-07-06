{ config, pkgs, perSystem, hostname, ... }: {
  programs.zsh = {
    enable = true;
    autocd = false;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    envExtra = ''
      KUBECTL_NS=default
    '';
    initContent = pkgs.lib.mkMerge [
      (pkgs.lib.mkOrder 550 (builtins.readFile ./autocomplete.zsh))
      (pkgs.lib.mkOrder 1000 ''
        bindkey -e
        bindkey "^[[3~" delete-char                    # Key Del
        bindkey "^[[5~" beginning-of-buffer-or-history # Key Page Up
        bindkey "^[[6~" end-of-buffer-or-history       # Key Page Down
        bindkey "^[[H" beginning-of-line               # Key Home
        bindkey "^[[F" end-of-line                     # Key End
        bindkey "^[^[[C" forward-word                  # Key Alt + Right
        bindkey "^[^[[D" backward-word                 # Key Alt + Left

        set-window-title() {
          window_title="\e]0;''${''${PWD/#"$HOME"/~}/projects/p}\a"
          echo -ne "$window_title"
        }

        set-window-title
        add-zsh-hook precmd set-window-title
      '')
    ];
    history = {
      ignoreAllDups = true;
    };
    plugins = [];
    shellAliases = {
      nup = let
        cmd = if pkgs.stdenv.isDarwin then "darwin-rebuild" else "nixos-rebuild";
        targets = {
          rcambrj = "macbook/#macbook";
          vm = "macbook/#vm";
        };
        target = targets.${hostname};
      in "sudo ${cmd} switch --flake ~/projects/nix/${target}";
      ngc = "sudo nix-collect-garbage -d";
      dwa = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";

      l = "ls -lah";
      vim = "nvim";
      ip = "curl ifconfig.co";
      tf = "terraform";
      sshn = "ssh -o StrictHostKeychecking=no -o UserKnownHostsFile=/dev/null";

      etch = "sudo dd status=progress bs=4M conv=fsync"; # if=foo.img of=/dev/disk69 && sync

      cpufreq = "watch -n.1 \"grep \\\"^[c]pu MHz\\\" /proc/cpuinfo\"";

      k = "kubectl";
      kk = "k -n $KUBECTL_NS";
      kga = "kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      git_status = {
        disabled = true;
      };
    };
  };
}