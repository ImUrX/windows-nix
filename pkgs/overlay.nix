{
  nixpkgs,
  nixpkgs-wine-10,
  erosanix,
  ...
}:
let
  inherit (nixpkgs.lib) composeManyExtensions;

in
{
  overlays.default = composeManyExtensions [
    (
      final: prev:
      let
        pkgsWine10 = import nixpkgs-wine-10 {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      in
      {
        inherit (erosanix.lib.${prev.stdenv.hostPlatform.system})
          mkWindowsAppNoCC
          copyDesktopIcons
          makeDesktopIcon
          ;
        winSources = final.callPackage ../_sources/generated.nix { };
        wine10Wow64Packages = pkgsWine10.wineWow64Packages;
      }
    )

    # New packaged added by us
    (import "${nixpkgs}/pkgs/top-level/by-name-overlay.nix" ./by-name)
  ];
}
