{ inputs, ... }: { lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # for language servers
    biome
    # dotnet-sdk_8
    go
    nil
    nixd
    terraform
  ];

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    profiles.default = {
      # package = pkgs.vscodium; # want liveshare goddamnit
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      userSettings = {
        "editor.tabSize" = 4;
        "editor.insertSpaces" = false;
        "editor.detectIndentation" = true;
        "liveshare.focusBehavior" = "prompt";
        "liveshare.guestApprovalRequired" = true;
        "workbench.startupEditor" = "newUntitledFile";
        "workbench.editor.enablePreviewFromQuickOpen" = false;
        "workbench.editor.tabSizing" = "shrink";
        "workbench.editor.tabActionCloseVisibility" = false;
        "editor.minimap.enabled" = false;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "editor.parameterHints.enabled" = false;
        "editor.suggestSelection" = "recentlyUsedByPrefix";
        "editor.rulers" = [ 80 100 120 ];
        "editor.acceptSuggestionOnEnter" = "off";
        "editor.acceptSuggestionOnCommitCharacter" = false;
        "editor.fontSize" = 14;
        "telemetry.telemetryLevel" = "off";
        "telemetry.enableCrashReporter" = false;
        "telemetry.enableTelemetry" = false;
        "redhat.telemetry.enabled" = false;
        "liveshare.authenticationProvider" = "GitHub";
        "liveshare.presence" = true;
        "gitlens.codeLens.enabled" = false;
        "gitlens.codeLens.recentChange.enabled" = false;
        "search.useIgnoreFiles" = false;
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/node_modules/**" = true;
        };
        "makefile.configureOnOpen" = true;

        # jnoortheen.nix-ide
        "nix.enableLanguageServer" = false; # keeps crashing
        "nix.serverPath" = "nixd"; # or nil

        "workbench.colorTheme" = "Dark+ (contrast)";
        "[javascript]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[javascriptreact]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[json]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[graphql]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[markdown]" = {
          "files.trimTrailingWhitespace" = false;
        };
        "[terraform]" = {
          "editor.defaultFormatter" = "hashicorp.terraform";
        };
        "[terraform-vars]" = {
          "editor.defaultFormatter" = "hashicorp.terraform";
        };
        "[go]" = {
          "editor.defaultFormatter" = "golang.go";
          "formatting.gofumpt" = true;
        };
        # AI
        "continue.enableTabAutocomplete" = false;
        "continue.showInlineTip" = false;
        "continue.telemetryEnabled" = false;
        # workaround https://github.com/nix-community/nixos-vscode-server/issues/82
        "remote.SSH.defaultExtensions" = [
          "ms-vsliveshare.vsliveshare"
          "mkhl.direnv"
          "golang.go"
          "hashicorp.terraform"
          "jnoortheen.nix-ide"
          "ms-vscode.makefile-tools"
          "orsenkucher.vscode-graphql"
          "tamasfe.even-better-toml"
          "pinage404.rust-extension-pack"
          # "biomejs.biome" # pkg needs installing on remote host
          "ms-python.python"
          "dingzhaojie.bit-peek"
        ];
      };
      extensions =
        with inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}; [
        # general
        vscode-marketplace.ms-vsliveshare.vsliveshare
        (vscode-marketplace.ms-vscode-remote.remote-ssh.override { meta.licence = []; })
        vscode-marketplace.k3a.theme-dark-plus-contrast
        vscode-marketplace.mkhl.direnv
        vscode-marketplace.stkb.rewrap # alt+q to wrap
        vscode-marketplace.continue.continue
        vscode-marketplace.github.vscode-github-actions
        vscode-marketplace.github.vscode-pull-request-github
        vscode-marketplace.dingzhaojie.bit-peek
        # open-vsx.jeanp413.open-remote-ssh

        # language-specific
        vscode-marketplace.ms-python.python
        vscode-marketplace.golang.go
        vscode-marketplace.hashicorp.terraform
        vscode-marketplace.jnoortheen.nix-ide
        # vscode-marketplace.bbenoist.nix
        vscode-marketplace.ms-vscode.makefile-tools
        vscode-marketplace.orsenkucher.vscode-graphql
        vscode-marketplace.tamasfe.even-better-toml
        vscode-marketplace.pinage404.rust-extension-pack
        # vscode-marketplace.esbenp.prettier-vscode
        vscode-marketplace.biomejs.biome

        # dotnet
        # vscode-marketplace.ms-dotnettools.vscode-dotnet-runtime
        # vscode-marketplace.ms-dotnettools.csharp
        # vscode-marketplace.ms-dotnettools.csdevkit
      ];
      keybindings = [
        {
          # https://github.com/continuedev/continue/issues/2913
          command = "editor.action.insertLineBefore";
          key = "shift+cmd+enter";
        }
      ];
    };
  };
}