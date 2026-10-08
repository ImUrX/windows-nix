{
  nixpkgs,
  nixpkgs-wine-10,
  nix-gaming,
  erosanix,
  ...
}:
let
  inherit (nixpkgs.lib)
    callPackageWith
    concatMapAttrs
    mapAttrs
    ;

  extraArgs =
    final:
    let
      inherit (final.stdenv.hostPlatform) system;
      pkgsWine10 = import nixpkgs-wine-10 {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      inherit (erosanix.lib.${system})
        mkWindowsAppNoCC
        copyDesktopIcons
        makeDesktopIcon
        ;
      inherit (nix-gaming.packages.${system}) wine-tkg;
      winSources = final.callPackage ../_sources/generated.nix { };
      wine10Wow64Packages = pkgsWine10.wineWow64Packages;
    };

  # Same layout as nixpkgs pkgs/by-name: by-name/<shard>/<name>/package.nix
  packageFiles = concatMapAttrs (
    shard: _:
    mapAttrs (name: _: ./by-name/${shard}/${name}/package.nix) (builtins.readDir ./by-name/${shard})
  ) (builtins.readDir ./by-name);
in
{
  overlays.default =
    final: prev:
    let
      callPackage = callPackageWith (final // extraArgs final);
    in
    mapAttrs (_: file: callPackage file { }) packageFiles;
}
