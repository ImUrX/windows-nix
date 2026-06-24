# windows-nix

This repository provides Nix packages as well as a Nixpkgs overlay for using Windows apps prepared to run inmediately.
The packages are automatically updated, built and cached regularly.
A list of packages in provided down in the [Packages section](#packages).

See [Usage](#usage) for information on how to set this up on your machine.

This depends on [mkWindowsApp](https://github.com/emmanuelrosa/erosanix/tree/master/pkgs/mkwindowsapp) made by @emmanuelrosa, most of the base files are grabbed from [nixpkgs-xr](https://github.com/nix-community/nixpkgs-xr) made by @Scrumplex which facilitated making the base repo,

## Usage

This repository provides a [Nixpkgs overlay](https://ryantm.github.io/nixpkgs/using/overlays/)
as well as the individual packages from that overlay.
While a Flake-based setup is the preferred way of using this repository,
you can also use itw without Flakes.

### Flake-based Setup

All you have to do, to apply this overlay to your NixOS configuration,
is to add the input `github:imurx/windows-nix` to your flake
and import the convenient NixOS module `windows-nix.nixosModules.windows-nix`.
See the example below.

> [!IMPORTANT]
> This module adds the Nixpkgs overlay as well as [the binary cache][binary-cache] for this repository.
> If you don't want the binary cache see [manual setup](#manually-setup-flake-overlay) below.

```nix
{
  inputs = {
    # ...
    windows-nix.url = "github:imurx/windows-nix";
  };

  outputs = { nixpkgs, windows-nix, ... }: {
    nixosConfigurations.foo = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        windows-nix.nixosModules.windows-nix
      ];
    };
  };
}
```

#### Manually setup Flake overlay

In case you want to have more control over the configuration, you can also choose to configure this manually.
Assuming your NixOS configuration is right in your `flake.nix`, you can write the following module:

```nix
{
  inputs = {
    # ...
    windows-nix.url = "github:imurx/windows-nix";
  };

  outputs = { nixpkgs, nixpkgs-xr, ... }: {
    nixosConfigurations.foo = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        {
          nixpkgs.overlays = [ windows-nix.overlays.default ];

          #nix.settings = {
          #  substituters = [ "https://windows-nix.cachix.org" ];
          #  trusted-public-keys = [ "windows-nix.cachix.org-1:WATVfLx463RnQLPIgyvv0aPsFl+Tyal9WRop1i2ZpxY=" ];
          #};
        }
      ];
    };
  };
}
```

### Traditional setup

Compatibility for traditional NixOS setups is provided using [flake-compat].
You can just add the following snippet to your configuration:

```nix
{ ... }:
let
  windows-nix = import (builtins.fetchTarball "https://github.com/nix-community/windows-nix/archive/main.tar.gz");
in
  {
    nixpkgs.overlays = [ windows-nix.overlays.default ];

    #nix.settings = {
    #  substituters = [ "https://windows-nix.cachix.org" ];
    #  trusted-public-keys = [ "windows-nix.cachix.org-1:WATVfLx463RnQLPIgyvv0aPsFl+Tyal9WRop1i2ZpxY=" ];
    #};
  }
```

You can also pin the tarball url using tools like [niv].

## Packages

This overlay provides the following packages:

- `autodesk-fusion`
- `copyDesktopIcons`
- `filmora-12`
- `pinga`
- `pingo`
- `rebelle-7`
- `wine-tkg`
- `xwintab`

[binary-cache]: https://app.cachix.org/cache/nix-community
[flake-compat]: https://github.com/edolstra/flake-compat
[niv]: https://github.com/nmattia/niv
