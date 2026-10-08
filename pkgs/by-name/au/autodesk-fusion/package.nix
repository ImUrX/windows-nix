{
  lib,
  mkWindowsAppNoCC,
  linkFarm,
  wineWow64Packages,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
  winSources,
}:

let
  # Fusion installs itself as a "stream" into a hashed directory under here.
  stream = ''"$WINEPREFIX/drive_c/Program Files/Autodesk/webdeploy/production/"*'';

  # The Wine Mono installer, in a directory Wine can install it from without prompting.
  # Its version must be the one this Wine expects, or Wine ignores it and prompts anyway.
  # nvfetcher picks that version, see nvfetcher.toml.
  monoMsi = "wine-mono-${winSources.wine-mono.version}-x86.msi";
  wineMono = linkFarm "wine-mono" { ${monoMsi} = winSources.wine-mono.src; };
in
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
  # Wine 11.0 - 11.10 is known to work. Starting with 11.11 the 3D canvas renders black.
  # https://codeberg.org/Lolig4/Autodesk-Fusion-360-on-Linux
  wine = wineWow64Packages.stable;
  enableVulkan = true;

  # `fileMap` can be used to set up automatic symlinks to files which need to be persisted.
  # The attribute name is the source path and the value is the path within the $WINEPREFIX.
  # But note that you must ommit $WINEPREFIX from the path.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper,
  # while the app is running.
  fileMap = {
    # No trailing slash: mkWindowsApp's `ln -s` fails on one, and the folder doesn't get linked.
    "$HOME/.config/${pname}" = "drive_c/users/$USER/AppData/Roaming/Autodesk";
    # Keeps the sign-in session.
    "$HOME/.local/share/${pname}/Identity Services" =
      "drive_c/users/$USER/AppData/Local/Autodesk/Identity Services";
  };

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  # Replaced by the notification at the start of winAppInstall, which also says how long it takes.
  enableInstallNotification = false;

  # This code will become part of the launcher script.
  # It will execute if the application needs to be installed,
  # which would happen either if the needed app layer doesn't exist,
  # or for some reason the needed Windows layer is missing, which would
  # invalidate the app layer.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  winAppInstall = ''
    notify-send -a "Autodesk Fusion" -i "$OUT_PATH/share/icons/hicolor/256x256/apps/${pname}.png" \
      "Installing Autodesk Fusion" "This takes about 15 minutes. Fusion will open when it's done."

    # The .NET installers below need Mono while Wine's builtin mscoree is still active.
    # Point Wine at a local copy so it installs Mono silently instead of prompting to download it.
    # winetricks removes Mono again before installing .NET.
    wine REG ADD "HKCU\Software\Wine\Dotnet" /v "MonoCabDir" /t REG_SZ /d "${wineMono}" /f

    # mscorsvw.exe hangs under Wine and never exits, so every `wineserver -w` (winetricks runs one after each verb) 
    # waits forever. It's an auto-start service, so it would come back on every launch.
    # .net works without it, it just compiles code at runtime.
    wine REG ADD "HKCU\Software\Wine\DllOverrides" /v "mscorsvw.exe" /t REG_SZ /d "" /f

    # https://codeberg.org/Lolig4/Autodesk-Fusion-360-on-Linux/src/branch/main/files/setup/autodesk_fusion_installer_x86-64.sh
    winetricks -q gdiplus arial verdana dotnet48 fontsmooth=rgb winhttp
    # Some of the verbs above reset the Windows version, so set it last.
    winetricks -q win11
    # Wine's HLSL compiler can't translate the shaders Fusion Electronics uses.
    winetricks -q d3dcompiler_47

    # The navigation bar doesn't work well with anything other than Wine's builtin DX9
    wine REG ADD "HKCU\Software\Wine\DllOverrides" /v "AdCefWebBrowser.exe" /t REG_SZ /d builtin /f
    wine REG ADD "HKCU\Software\Wine\DllOverrides" /v "d3d9" /t REG_SZ /d builtin /f
    # Use the Visual C++ runtime bundled with Fusion. Wine's msvcp140 lacks std::get_new_handler.
    wine REG ADD "HKCU\Software\Wine\DllOverrides" /v "msvcp140" /t REG_SZ /d "native,builtin" /f
    # Fusion hangs on the "Initializing" splash screen while Chromium enumerates audio devices
    # through Wine's PulseAudio driver. The ALSA driver doesn't hang, and still reaches PipeWire/PulseAudio
    # through ALSA's default device.
    wine REG ADD "HKCU\Software\Wine\Drivers" /v "Audio" /t REG_SZ /d "alsa" /f
    # Autodesk's analytics service. Fusion runs fine without it.
    wine REG ADD "HKCU\Software\Wine\DllOverrides" /v "adpclientservice.exe" /t REG_SZ /d "" /f

    wine ${winSources.webview2.src} /silent /install

    # mkWindowsApp mounts the prefix through unionfs (FUSE), which makes the installer much slower.
    # Let it install into a real directory instead, and move the result into the prefix afterwards.
    staging="$(mktemp -d -p "''${XDG_CACHE_HOME:-$HOME/.cache}" ${pname}-install.XXXXXX)"
    ln -s "$staging" "$WINEPREFIX/drive_c/Program Files/Autodesk"

    wine ${src} --quiet

    # The WebView2 updater never exits, which would make mkWindowsApp's `wineserver -w` hang.
    wineserver -k

    rm "$WINEPREFIX/drive_c/Program Files/Autodesk"
    mv "$staging" "$WINEPREFIX/drive_c/Program Files/Autodesk"

    # Use the DirectX 11 renderer (through DXVK) instead of the default.
    for dir in Roaming Local; do
      install -Dm644 ${./NMachineSpecificOptions.xml} \
        "$WINEPREFIX/drive_c/users/$USER/AppData/$dir/Autodesk/Neutron Platform/Options/NMachineSpecificOptions.xml"
    done
    notify-send -a "Autodesk Fusion" -i "$OUT_PATH/share/icons/hicolor/256x256/apps/${pname}.png" \
      "Finished install Autodesk Fusion" "Fusion will open now."
  '';

  # This code will become part of the launcher script.
  # It will execute after winAppInstall and winAppPreRun (if needed),
  # to run the application.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  # Command line arguments are in $ARGS, not $@
  # DO NOT BLOCK. For example, don't run: wineserver -w
  winAppRun = ''
    export QTWEBENGINE_DISABLE_SANDBOX=1
    export DXVK_LOG_LEVEL=none
    export WINEDEBUG="''${WINEDEBUG:--all}"

    # Wine maps Unix file names with LC_CTYPE, a non-UTF-8 locale mangles them.
    if [ "$(locale charmap 2>/dev/null)" != "UTF-8" ]; then
      export LC_CTYPE="C.UTF-8"
    fi

    case "$ARGS" in
      adskidmgr:*)
        # Sign-in callback from the browser. Hand it to the Identity Manager of the running Fusion.
        wine ${stream}/"Autodesk Identity Manager/AdskIdentityManager.exe" "$ARGS"
        ;;
      *)
        # Updates would be lost anyway, since the runtime layer is thrown away on exit.
        # Fusion is updated by bumping the installer in nvfetcher.toml instead.
        wine ${stream}/Fusion360.exe --disableupdatecheck
        wineserver -k
        ;;
    esac
  '';

  installPhase = ''
    runHook preInstall

    OLD_LAUNCHER=$out/bin/.launcher
    NEW_LAUNCHER=$out/bin/${pname}
    # Correct `MY_PATH` in launcher script
    substituteInPlace $OLD_LAUNCHER \
      --replace-fail $OLD_LAUNCHER $NEW_LAUNCHER
    mv $OLD_LAUNCHER $NEW_LAUNCHER

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Autodesk Fusion";
      genericName = "CAD Application";
      startupWMClass = "fusion360.exe";
      categories = [
        "Engineering"
        "Graphics"
      ];
    })
    (makeDesktopItem {
      name = "adskidmgr-opener";
      exec = "${pname} %u";
      desktopName = "Autodesk Identity Manager";
      noDisplay = true;
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
    homepage = "https://www.autodesk.com/products/fusion-360";
    license = licenses.unfree;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
