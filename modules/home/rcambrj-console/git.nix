{ ... }:
let
  me = import ./me.nix;
in {
  programs.git = {
    enable = true;
    userName = me.name;
    userEmail = me.email;
    ignores = [
      ".envrc"
      ".vscode"
    ];
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core.abbrev = 7;
      core.editor = "vim";
      core.autocrlf = "input";
      core.pager = "less -F -X";
      color.ui = "auto";
      merge.log = true;
      push.default = "current";
      difftool.prompt = false;
      mergetool.prompt = false;
      pull.rebase = true;
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };

  programs.zsh.shellAliases = {
    g    = "git";
    # git reset
    grs  = "git reset";
    grss = "git reset --soft";
    grsh = "git reset --hard";
    grso = "git reset --hard origin/`git rev-parse --abbrev-ref HEAD`";
    grsm = "git reset --hard origin/main";
    # git rebase
    grb  = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    grbs = "git rebase --skip";
    grbo = "git rebase origin/`git rev-parse --abbrev-ref HEAD`";
    grbm = "git rebase origin/main";
    # git cherry-pick
    gcp  = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";
    # git other
    gcl  = "git clone";
    gst  = "git status";
    gsp  = "git stash push";
    gsa  = "git stash apply";
    gf   = "git fetch --all --prune --jobs=10";
    gpr  = "git pull --rebase";
    gd   = "git diff";
    gds  = "git diff --staged";
    ga   = "git add";
    gco  = "git checkout";
    gci  = "git commit";
    gcia = "git commit --amend";
    gp   = "git push";
    gpf  = "git push --force-with-lease";
    gh   = "git rev-parse --short HEAD";
  };
}