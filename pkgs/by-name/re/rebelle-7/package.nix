{
  lib,
  mkWindowsAppNoCC,
  wine10Wow64Packages,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
  winSources,
  xwintab,
}:

mkWindowsAppNoCC rec {
  inherit (winSources.rebelle-7)
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
  wine = wine10Wow64Packages.stable;

  # `fileMap` can be used to set up automatic symlinks to files which need to be persisted.
  # The attribute name is the source path and the value is the path within the $WINEPREFIX.
  # But note that you must ommit $WINEPREFIX from the path.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper,
  # while the app is running.
  fileMap = {
    "$HOME/.config/${pname}" = "drive_c/users/$USER/AppData/Local/Escape Motions/Rebelle 7";
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
    ${wine}/bin/wine ${src} /VERYSILENT /SUPPRESSMSGBOXES

    # Symlink XWinTab DLLs to system32
    SYS_DIR="$WINEPREFIX/drive_c/windows/system32"
    mkdir -p "$SYS_DIR"
    ln -sf "${xwintab}/wintab32.dll" "$SYS_DIR/"
    ln -sf "${xwintab}/XWinTabHelper.dll.so" "$SYS_DIR/"
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
    export WINEDLLOVERRIDES="wintab32=n,b;$WINEDLLOVERRIDES"
    ${wine}/bin/wine "$WINEPREFIX/drive_c/Program Files/Rebelle 7/Rebelle 7.exe" "$ARGS"
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
      desktopName = "Rebelle 7";
      genericName = "Digital Painting";
      categories = [ "Graphics" ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = pname;
    src = ./icon.png;
  };

  meta = with lib; {
    description = "Real media paint software for digital painting, with simulation of real-world color mixing, blending, wet-diffusion and drying.";
    homepage = "https://www.escapemotions.com/products/rebelle";
    license = licenses.unfree;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
