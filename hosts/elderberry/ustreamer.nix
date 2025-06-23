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
      "--device=/dev/video0"

      # speeds measured with `usbtop`
      # "--resolution=640x360"   # ~6Mb/s
      # "--resolution=1024x576"  # ~12Mb/s
      # "--resolution=1280x720"  # ~18Mb/s
      # "--resolution=1920x1080" # ~24Mb/s
      "--resolution=2560x1440" # ~24Mb/s
      "--desired-fps=15"
      "--format=MJPEG"

      # hardware offloading
      # "--encoder=M2M-VIDEO" # GPU-accelerated MJPEG encoding
      "--encoder=HW" # Use pre-encoded MJPEG frames directly from camera hardware

      # "--slowdown" # no effect because minimum framerate is 15
      # "--quality=80" # not supported by this camera
    ];
  };

  systemd.services.ustreamer.serviceConfig.Restart = "always";

  services.fluidd.nginx.locations = {
    "/webcam/snapshot" = {
      proxyPass = "http://127.0.0.1:${builtins.toString port}/snapshot";
    };
    # very CPU intensive because raspi3 lacks aes hardware for fast https encryption
    # "/webcam/stream" = {
    #   proxyPass = "http://127.0.0.1:${builtins.toString port}/stream";
    # };
  };
}