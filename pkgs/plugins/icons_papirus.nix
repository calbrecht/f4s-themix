{ pkgs
, srcs
, version
}:

pkgs.stdenv.mkDerivation rec {

  pname = "themix-icons-papirus";

  inherit srcs;
  inherit version;

  nativeBuildInputs = with pkgs; [ gettext ];

  passthru = {
    pluginName = "icons_papirus";
  };

  unpackPhase = ''
    runHook preUnpack

    read -r themix papirus <<<"$srcs"

    cp -r --no-preserve=mode "$themix" source
    cp -r --no-preserve=mode -T "$papirus" source/plugins/icons_papirus/papirus-icon-theme

    export sourceRoot=source
    echo "source root is $sourceRoot";

    runHook postUnpack
  '';

  dontBuild = true;

  installFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "APPDIR="
  ];

  installTargets = "install_icons_papirus";

  postPatch = ''
    substituteInPlace plugins/icons_papirus/change_color.sh \
      --replace "cp -R" "cp -R --no-preserve=mode,timestamps"
  '';

  postInstall = ''
    chmod a+x plugins/icons_papirus/change_color.sh
  '';

  meta = with pkgs.lib; {
  };
}
