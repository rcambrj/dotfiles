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

    # intel-media-sdk
    # error: Package ‘intel-media-sdk-23.2.2’ in /nix/store/182c2qj20sfspzxcshd6p051qdx3mx5j-source/pkgs/by-name/in/intel-media-sdk/package.nix:65 is marked as insecure, refusing to evaluate.
    # Known issues:
    # - End of life with various local privilege escalation vulnerabilites:
    # - CVE-2023-22656
    # - CVE-2023-45221
    # - CVE-2023-47169
    # - CVE-2023-47282
    # - CVE-2023-48368
    # nixpkgs.config.permittedInsecurePackages = [
    # "intel-media-sdk-23.2.2"
    # ];


    intel-compute-runtime
    libva-utils
  ];

}