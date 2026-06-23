{
  lib,
  stdenvNoCC,
  autoPatchelfHook,
  libxcb,
  winSources,
}:

stdenvNoCC.mkDerivation {
  inherit (winSources.xwintab)
    pname
    version
    ;

  src = winSources.xwintab.src.overrideAttrs (_: {
    stripRoot = false;
  });

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    libxcb
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp wintab32.dll $out/
    cp XWinTabHelper.dll.so $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "XWinTab - X11 to Windows Tablet API bridge for Wine";
    homepage = "https://github.com/Graham--M/XWinTab";
    license = licenses.mit;
    maintainers = with maintainers; [
      imurx
    ];
    platforms = [ "x86_64-linux" ];
  };
}
