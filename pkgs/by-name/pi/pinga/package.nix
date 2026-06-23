{
  lib,
  mkWindowsAppNoCC,
  wineWow64Packages,
  winSources,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
}:

mkWindowsAppNoCC rec {
  inherit (winSources.pinga)
    pname
    version
    src
    ;

  # By default, when a Wine prefix is first created Wine will produce a warning prompt if Mono is not installed.
  # This doesn't happen with the Wine "full" packages, but it does happen with the "base" packages.
  # When this option is set to 'false', DLL overrides are used when the Wine prefix is created, to bypass the prompt.
  enableMonoBootPrompt = false;
  dontUnpack = true;
  wineArch = "win64";
  wine = wineWow64Packages.stable;

  # `fileMap` can be used to set up automatic symlinks to files which need to be persisted.
  # The attribute name is the source path and the value is the path within the $WINEPREFIX.
  # But note that you must ommit $WINEPREFIX from the path.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper,
  # while the app is running.
  fileMap = {
    "$HOME/.config/pinga.ini" = "drive_c/users/$USER/AppData/Local/pinga.ini";
  };

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  # This code will become part of the launcher script.
  # It will execute if the application needs to be installed,
  # which would happen either if the needed app layer doesn't exist,
  # or for some reason the needed Windows layer is missing, which would
  # invalidate the app layer.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  winAppInstall = ''
    wine "${src}/pinga.exe" /VERYSILENT /SUPPRESSMSGBOXES
  '';

  # This code runs before winAppRun, but only for the first instance.
  # Therefore, if the app is already running, winAppRun will not execute.
  # Use this to do any setup prior to running the app.
  winAppPreRun = "";

  # This code will become part of the launcher script.
  # It will execute after winAppInstall and winAppPreRun (if needed),
  # to run the application.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  # Command line arguments are in $ARGS, not $@
  # DO NOT BLOCK. For example, don't run: wineserver -w
  winAppRun = ''
    wine "$WINEPREFIX/drive_c/Program Files/pinga/pinga.exe" "$ARGS"
  '';

  # This code will run after winAppRun, but only for the first instance.
  # Therefore, if the app was already running, winAppPostRun will not execute.
  # In other words, winAppPostRun is only executed if winAppPreRun is executed.
  # Use this to do any cleanup after the app has terminated
  winAppPostRun = "";

  # This is a normal mkDerivation installPhase, with some caveats.
  # The launcher script will be installed at $out/bin/.launcher
  # DO NOT DELETE OR RENAME the launcher. Instead, link to it as shown.
  installPhase = ''
    runHook preInstall

    mv $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "pinga";
      genericName = "Image Optimizer";
      categories = [ "Graphics" ];
      mimeTypes = [
        "image/jpeg"
        "image/png"
        "image/apng"
      ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = pname;
    src = ./icon.png;
  };

  meta = with lib; {
    description = "pinga is an easy to use GUI, experimental image optimizer (PNG, JPEG, APNG) designed to be used for web context.";
    homepage = "https://css-ig.net/pinga";
    license = licenses.unfree;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
