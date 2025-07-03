# TODO: once stable, make a reusable module of this
{ config, ... }: {
  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
    };
  };

  services.alloy = {
    enable = true;
    extraFlags = [ "--disable-reporting" ];
  };

  environment.etc."alloy/config.alloy" = {
    text = ''
      loki.write "local" {
        endpoint {
          url = "https://loki.home.cambridge.me/loki/api/v1/push"
        }
      }

      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
        rule {
          source_labels = ["__journal__boot_id"]
          target_label  = "boot_id"
        }
        rule {
          source_labels = ["__journal__transport"]
          target_label  = "transport"
        }
        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
        rule {
          source_labels = ["__journal__hostname"]
          target_label  = "instance"
        }
      }

      loki.source.journal "read" {
        forward_to = [
          loki.write.local.receiver,
        ]
        relabel_rules = loki.relabel.journal.rules
        labels = {
          "host" = "${config.networking.hostName}",
        }
      }
    '';
  };
}