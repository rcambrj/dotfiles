{ config, pkgs, ... }: {
  # https://github.com/webos-tools/cli
  # https://webostv.developer.lge.com/develop/getting-started/developer-mode-app
  #
  # use https://github.com/webosbrew/dev-manager-desktop to authenticate
  # then put contents of /var/luna/preferences/devmode_enabled
  # into agenix secret "webos-dev-mode-curl" in this format:
  # url=https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=$token
  # (see curl -K)

  services.home-assistant.config = {
    shell_command = {
      extend_webos_dev_mode = "${pkgs.curl}/bin/curl --no-progress-meter -K ${config.age.secrets.webos-dev-mode-curl.path}";
    };
    automation = [{
      alias = "Extend WebOS dev mode";
      mode = "single";
      trigger = {
        # would rather a longer interval but time_pattern(days=/3) is not possible
        platform = "time";
        at = "03:33";
      };
      action = [
        {
          action = "shell_command.extend_webos_dev_mode";
        }
      ];
    }];
  };
}