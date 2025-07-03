{ ... }: {
  imports = [
    ./grafana.nix
    ./influxdb.nix
    ./loki.nix
    ./prometheus.nix
    ./telegraf.nix
  ];
}