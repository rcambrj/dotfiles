{ pkgs, ... }: with pkgs; stdenv.mkDerivation {
  name = "lldap-ha-auth";

  src = fetchFromGitHub {
    owner = "lldap";
    repo = "lldap";
    rev = "9ac96e8c6e4b015ee10ddcc978ece6da34d38911";
    hash = "sha256-zuJNe6GY8P2EpVA87q4TAbCGlT4B5FypZeLrNUzxtWc=";
  };

  nativeBuildInputs = [  makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp example_configs/lldap-ha-auth.sh $out/bin/lldap-ha-auth
    chmod +x $out/bin/lldap-ha-auth
    wrapProgram $out/bin/lldap-ha-auth --prefix PATH : ${lib.makeBinPath ([ curl jq gnused ])}
  '';
}