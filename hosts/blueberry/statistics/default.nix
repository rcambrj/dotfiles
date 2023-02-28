{ ... }: {
  imports = [
    ./prometheus.nix
    ./grafana.nix
    ./telegraf.nix
    ./influxdb.nix
  ];
}