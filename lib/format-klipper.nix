# https://github.com/NixOS/nixpkgs/blob/d5493eb70174b5e342553ad973206c5ce35497cf/nixos/modules/services/misc/klipper.nix#L9
pkgs: pkgs.formats.ini {
  # https://github.com/NixOS/nixpkgs/pull/121613#issuecomment-885241996
  listToValue =
    l:
    if builtins.length l == 1 then
      pkgs.lib.generators.mkValueStringDefault { } (pkgs.lib.head l)
    else
      pkgs.lib.concatMapStrings (s: "\n  ${pkgs.lib.generators.mkValueStringDefault { } s}") l;
  mkKeyValue = pkgs.lib.generators.mkKeyValueDefault { } ":";
}