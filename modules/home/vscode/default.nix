{ inputs, ... }: { config, lib, pkgs, ... }: {
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
        "workbench.secondarySideBar.defaultVisibility" = "hidden";

        # jnoortheen.nix-ide
        "nix.enableLanguageServer" = false; # keeps crashing
        "nix.serverPath" = "nixd"; # or nil

        "workbench.colorTheme" = "Dark+ (contrast)";
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
      };
      extensions =
        with inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}; [
        # general
        vscode-marketplace.ms-vsliveshare.vsliveshare
        vscode-marketplace.k3a.theme-dark-plus-contrast
        vscode-marketplace.mkhl.direnv
        vscode-marketplace.stkb.rewrap # alt+q to wrap
        vscode-marketplace.github.vscode-github-actions
        vscode-marketplace.dingzhaojie.bit-peek

        # language-specific
        vscode-marketplace.mxsdev.typescript-explorer
        vscode-marketplace.ms-python.python
        vscode-marketplace.golang.go
        vscode-marketplace.hashicorp.terraform
        vscode-marketplace.jnoortheen.nix-ide
        # vscode-marketplace.bbenoist.nix
        vscode-marketplace.ms-vscode.makefile-tools
        # vscode-marketplace.orsenkucher.vscode-graphql
        vscode-marketplace.tamasfe.even-better-toml
        vscode-marketplace.pinage404.rust-extension-pack
        vscode-marketplace.platformio.platformio-ide

        # use the nixpkgs version because https://github.com/nix-community/nix-vscode-extensions/blob/674d9cb4cfe1a4a989921221b4a2d0e0a4e898a9/nix/removed.nix#L6
        pkgs.vscode-extensions.ms-vscode.cpptools
        pkgs.vscode-extensions.ms-vscode.cmake-tools

        # dotnet
        # vscode-marketplace.ms-dotnettools.vscode-dotnet-runtime
        # vscode-marketplace.ms-dotnettools.csharp
        # vscode-marketplace.ms-dotnettools.csdevkit
      ];
    };
  };
}