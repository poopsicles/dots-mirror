{ lib, config, ... }:

{
  options = {
    my.starship.enable = lib.mkEnableOption "starship with home-manager";
  };

  config = lib.mkIf config.my.starship.enable {
    programs.starship = {
      enable = true;

      settings = {
        add_newline = false;
        command_timeout = 1000;
        nix_shell.symbol = "❄️ "; # there's two spaces after by default
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✖](bold red)";
        };
        hostname = {
          ssh_only = false;
          format = "[$hostname](bold green): ";
        };
        username = {
          show_always = true;
          format = "[$user](bold lavender)[@](bold yellow)";
        };
      };
    };

    programs.zsh.initContent = ''
      ############################## extra starship zsh config ##############################

      # add a blank line between prompts because starship's add_newline is annoying on first open
      precmd() { precmd() { echo "" } }
      alias clear='precmd() { precmd() { echo "" } } && clear'
      alias reset='precmd() { precmd() { echo "" } } && reset'

      ############################ end extra starship zsh config ############################
    '';
  };
}
