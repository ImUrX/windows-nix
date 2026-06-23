{
  lib,
  stdenvNoCC,
  runtimeShell,
  wineWow64Packages,
  winSources,
}:

stdenvNoCC.mkDerivation rec {
  inherit (winSources.pingo)
    pname
    version
    src
    ;

  nativeBuildInputs = [
    wineWow64Packages.stable
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cat <<'EOF' > $out/bin/pingo
    #!${runtimeShell}
    export WINEARCH=win64
    export WINEPREFIX="''${XDG_DATA_HOME:-"''${HOME}/.local/share"}/pingo"
    export WINEDLLOVERRIDES="mscoree=" # disable mono
    if [ ! -d "$WINEPREFIX" ] || [ ! "$(readlink "$WINEPREFIX/pingo.exe")" -ef "${src}/pingo.exe" ] ; then
      mkdir -p "$WINEPREFIX"
      ln -sf "${src}/pingo.exe" "$WINEPREFIX/pingo.exe"
    fi
    ${wineWow64Packages.stable}/bin/wine "$WINEPREFIX/pingo.exe" $@
    EOF
    chmod +x $out/bin/pingo

    runHook postInstall
  '';

  meta = with lib; {
    description = "pingo is an experimental lossless and lossy image optimizer (PNG, JPEG, WebP, APNG) designed to be used for web context.";
    homepage = "https://css-ig.net/pingo";
    license = licenses.unfree;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
