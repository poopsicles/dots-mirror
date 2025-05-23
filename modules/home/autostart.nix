{
  lib,
  config,
  pkgs,
  ...
}:

# stolen from https://github.com/nix-community/home-manager/issues/3447
# TODO: maybe upstream? adapt to darwin
let
  cfg = config.my.autostart;
in
with lib;
{
  options = {
    my.autostart = {
      enable = mkEnableOption "home-manager managed startup programs";
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    home.file = mkIf pkgs.stdenv.isLinux (
      builtins.listToAttrs (
        map (pkg: {
          name = ".config/autostart/" + pkg.pname + ".desktop";
          value =
            if pkg ? desktopItem then
              {
                # Application has a desktopItem entry.
                # Assume that it was made with makeDesktopEntry, which exposes a
                # text attribute with the contents of the .desktop file
                text = pkg.desktopItem.text;
              }
            else
              {
                # Application does *not* have a desktopItem entry. Try to find a
                # matching .desktop name in /share/applications
                source =
                  with builtins;
                  let
                    appsPath = "${pkg}/share/applications";
                    # function to filter out subdirs of /share/applications
                    filterFiles =
                      dirContents:
                      lib.attrsets.filterAttrs (
                        _: fileType:
                        elem fileType [
                          "regular"
                          "symlink"
                        ]
                      ) dirContents;
                  in
                  (
                    # if there's a desktop file by the app's pname, use that
                    if (pathExists "${appsPath}/${pkg.pname}.desktop") then
                      "${appsPath}/${pkg.pname}.desktop"
                    # if there's not, find the first desktop file in the app's directory and assume that's good enough
                    else
                      (
                        if pathExists "${appsPath}" then
                          "${appsPath}/${head (attrNames (filterFiles (readDir "${appsPath}")))}"
                        else
                          throw "no desktop file for app ${pkg.pname}"
                      )
                  );
              };
        }) cfg.packages
      )
    );
  };
}
