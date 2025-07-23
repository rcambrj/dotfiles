{ pkgs, ... }: {
  # required for Jellyfin

  boot.kernelParams = [ "i915.enable_guc=2" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  environment.systemPackages = with pkgs; [
    intel-gpu-tools # intel_gpu_top
    intel-compute-runtime
    libva-utils
  ];
}