{
  flake-utils,
  nixpkgs,
  self,
  ...
}:
flake-utils.lib.eachDefaultSystem (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;
  in
  {
    apps.update-readme = flake-utils.lib.mkApp {
      drv = pkgs.writeShellApplication {
        name = "update-readme";
        text = ''
          cat ${
            pkgs.replaceVars ../README-template.md {
              packageNames = lib.concatMapStringsSep "\n" (name: "- `${name}`") (
                builtins.attrNames self.packages.${system}
              );
            }
          } > README.md
        '';
      };
    };
  }
)
