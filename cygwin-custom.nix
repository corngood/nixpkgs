{
  lib,
  pkgs,
  config,
  ...
}:

{
  config = {
    nix.extraOptions = ''
      secret-key-files = /var/store-key
    '';

    environment.systemPackages = [ pkgs.curl ];
  };
}
