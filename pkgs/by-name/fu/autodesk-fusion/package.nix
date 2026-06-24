{
  lib,
  mkWindowsAppNoCC,
  coreutils,
  findutils,
  wineWow64Packages,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
  winSources,
}:

mkWindowsAppNoCC rec {
  inherit (winSources.autodesk-fusion)
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
  wine = wineWow64Packages.staging;
  enableVulkan = true;

  # `fileMap` can be used to set up automatic symlinks to files which need to be persisted.
  # The attribute name is the source path and the value is the path within the $WINEPREFIX.
  # But note that you must ommit $WINEPREFIX from the path.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper,
  # while the app is running.
  fileMap = {
    "$HOME/.config/${pname}" = "drive_c/users/$USER/AppData/Roaming/Autodesk/";
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
    winetricks -q corefonts vkd3d dotnet48 vcrun2015
    wine ${winSources.webview2.src} /silent /install

    mkdir -p "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Microsoft/Internet Explorer/Quick Launch/User Pinned"

    ${coreutils}/bin/timeout -k 10m 9m wine ${src} --quiet
    ${coreutils}/bin/sleep 5
    ${coreutils}/bin/timeout -k 5m 1m wine ${src} --quiet
    wineserver -k
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
    ACTUAL_DIR="$WINEPREFIX/drive_c/Program Files/Autodesk/webdeploy/production"
    if [ "$1" = run ]; then
      wine "$(${findutils}/bin/find "$ACTUAL_DIR" -iname fusion360.exe | head -1)" "$ARGS"
    else
      wine "$(${findutils}/bin/find "$ACTUAL_DIR" -name AdskIdentityManager.exe | head -1)" "$ARGS"
    fi
    wineserver -k
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

    ln -s $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = "${pname} run";
      icon = pname;
      desktopName = "Autodesk Fusion";
      genericName = "CAD Application";
      categories = [
        "Engineering"
        "Graphics"
      ];
    })
    (makeDesktopItem {
      name = "adskidmgr-opener";
      exec = "${pname} %u";
      desktopName = "adskidmgr Scheme Handler";
      startupNotify = false;
      mimeTypes = [ "x-scheme-handler/adskidmgr" ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = pname;
    src = ./icon.png;
  };

  meta = with lib; {
    description = "A computer-aided design, computer-aided manufacturing, computer-aided engineering and printed circuit board design software application";
    homepage = "https://filmora.wondershare.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
