{ pkgs, perSystem, ... }: {
  programs.zsh = {
    enable = true;
    autocd = false;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    # initExtraFirst = "";
    initExtraBeforeCompInit = builtins.readFile ./autocomplete.zsh;
    initExtra = ''
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
    '';
    history = {
      ignoreAllDups = true;
    };
    plugins = [];
    shellAliases = {
      nup = if pkgs.stdenv.isDarwin then "darwin-rebuild switch --flake ~/projects/nix/macbook/#macbook" else "nixos-rebuild switch";
      ngc = "sudo nix-collect-garbage -d";
      dwa = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";

      l = "ls -lah";
      vim = "nvim";
      ip = "curl ifconfig.co";
      tf = "terraform";
      sshn = "ssh -o StrictHostKeychecking=no -o UserKnownHostsFile=/dev/null";

      etch = "sudo dd status=progress bs=4M conv=fsync"; # if=foo.img of=/dev/disk69 && sync

      cpufreq = "watch -n.1 \"grep \\\"^[c]pu MHz\\\" /proc/cpuinfo\"";
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