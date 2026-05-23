{ config, inputs, lib, pkgs, ... }: {
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  age.secrets = {
    hermes-agent.file = ../../secrets/hermes-agent.age;
    opencode-go-api-key.file = ../../secrets/opencode-go-api-key.age;
    telegram-hermes-bot-key.file = ../../secrets/telegram-hermes-bot-key.age;
    telegram-group.file = ../../secrets/telegram-group.age;
    telegram-rcambrj-user-id.file = ../../secrets/telegram-rcambrj-user-id.age;
    telegram-squidlizard-user-id.file = ../../secrets/telegram-squidlizard-user-id.age;
  };

  age-template.files = {
    hermes-env = {
      vars = {
        api_key = config.age.secrets.hermes-agent.path;
        opencode_go_api_key = config.age.secrets.opencode-go-api-key.path;
        telegram_hermes_bot_key = config.age.secrets.telegram-hermes-bot-key.path;
        telegram_group = config.age.secrets.telegram-group.path;
        telegram_rcambrj_user_id = config.age.secrets.telegram-rcambrj-user-id.path;
        telegram_squidlizard_user_id = config.age.secrets.telegram-squidlizard-user-id.path;
      };
      content = ''
        API_SERVER_KEY=$api_key
        OPENCODE_GO_API_KEY=$opencode_go_api_key
        TELEGRAM_BOT_TOKEN=$telegram_hermes_bot_key
        TELEGRAM_HOME_CHANNEL=$telegram_group
        TELEGRAM_ALLOWED_USERS=$telegram_rcambrj_user_id,$telegram_squidlizard_user_id
      '';
    };
    open-webui-env = {
      vars.api_key = config.age.secrets.hermes-agent.path;
      content = ''
        OPENAI_API_KEY=$api_key
      '';
    };
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ];
    container.enable = true;
    container.hostUsers = [ "nixos" ];
    environment = {
      # API_SERVER_ENABLED = "true";
      # API_SERVER_HOST = "127.0.0.1";
      # API_SERVER_PORT = "8642";
      # API_SERVER_MODEL_NAME = "Hermes Agent";
    };
    environmentFiles = [
      config.age-template.files.hermes-env.path
    ];
    settings = {
      model = {
        provider = "opencode-go";
        default = "deepseek-v4-flash";
        context_length = 1000000;
      };
      terminal = {
        backend = "docker";
        timeout = 180;
        docker_volumes = [
          "/home/user/.hermes/cache/documents:/output"
        ];
      };
      approvals.mode = "off";
    };
  };
}
