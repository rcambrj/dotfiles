{ ... }: {
  services.esphome = {
    enable = true;
    usePing = true;
    address = "0.0.0.0";
  };
}