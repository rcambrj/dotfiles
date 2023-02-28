{ ... }: {
  services.home-assistant = {
    lovelaceConfigWritable = true;
    lovelaceConfig = {
      # show defaults. use this to temporarily see the shape of new integrations
      strategy = {
        type = "original-states";
      };
      # title = "Overview";
      # views = [
      #   {
      #     title = "Lights";
      #     cards = [ {
      #       type = "markdown";
      #       title = "Lovelace";
      #       content = "Welcome to your **Lovelace UI**.";
      #     } ];        }
      # ];
    };
  };
}