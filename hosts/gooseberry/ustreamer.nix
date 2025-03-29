{ pkgs, ... }: {
  # v4l2-ctl --list-devices
  # v4l2-ctl --dev /dev/video0 --list-formats-ext
  environment.systemPackages = with pkgs; [
    v4l-utils
  ];

  services.ustreamer = {
    enable = true;
    # device = "/dev/v4l/by-id/usb-webcamvendor_webcamproduct_00000000-video-index0";
    extraArgs = [
      "--resolution=2560x1440"
      "-f 30"
      # https://github.com/mainsail-crew/crowsnest/blob/d0c2ca5d1613d81cdb17cded1438d4bc5d6b0995/libs/ustreamer.sh#L59
      # "-m MJPEG"
      # "--encoder=HW"
    ];
  };

  services.fluidd.nginx.locations = {
    "/webcam/snapshot" = {
      proxyPass = "http://localhost:8080/snapshot";
    };
    "/webcam/stream" = {
      proxyPass = "http://localhost:8080/stream";
    };
  };
}