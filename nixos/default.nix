{ self, ... }:
{
  nixosModules.windows-nix =
    {
      config,
      lib,
      system,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        ;
      cfg = config.windows-nix;
    in
    {
      options.windows-nix.enable = mkEnableOption "windows-nix overlay" // mkOption { default = true; };

      config = mkIf cfg.enable {
        nixpkgs.overlays = [
          self.overlays.default
        ];

        nix.settings = {
          substituters = [ "https://windows-nix.cachix.org" ];
          trusted-public-keys = [ "windows-nix.cachix.org-1:WATVfLx463RnQLPIgyvv0aPsFl+Tyal9WRop1i2ZpxY=" ];
        };
      };
    };
}
