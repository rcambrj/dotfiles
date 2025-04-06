{ pkgs, ... }: let
  port = 22678;
in {
  # v4l2-ctl --list-devices
  # v4l2-ctl --dev /dev/video0 --list-formats-ext
  environment.systemPackages = with pkgs; [
    v4l-utils
  ];

  networking.firewall.allowedTCPPorts = [
    port
  ];

  services.ustreamer = {
    enable = true;
    listenAddress = "0.0.0.0:${builtins.toString port}";
    # https://github.com/pikvm/ustreamer/blob/afd305e87dd2927d8e65da77f5ccfd0c7c119bd3/man/ustreamer.1
    # https://github.com/mainsail-crew/crowsnest/blob/d0c2ca5d1613d81cdb17cded1438d4bc5d6b0995/libs/ustreamer.sh#L59
    extraArgs = [
      "--resolution=2560x1440"
      "--desired-fps=15"
      "--device-timeout=2"
      "--format=MJPEG"

      # hardware offloading
      # "--encoder=M2M-VIDEO" # GPU-accelerated MJPEG encoding
      "--encoder=HW" # Use pre-encoded MJPEG frames directly from camera hardware

      # "--quality=80" # not supported by this camera
    ];
  };

  systemd.services.ustreamer.serviceConfig.Restart = "always";

  services.fluidd.nginx.locations = {
    "/webcam/snapshot" = {
      proxyPass = "http://localhost:${builtins.toString port}/snapshot";
    };
    # very CPU intensive because raspi3 lacks aes hardware for fast https encryption
    # "/webcam/stream" = {
    #   proxyPass = "http://localhost:${builtins.toString port}/stream";
    # };
  };
}