{ pkgs
, src
, version
}:

pkgs.stdenv.mkDerivation rec {

  pname = "oomox-gtk-theme";

  inherit src;
  inherit version;

  buildInputs = with pkgs; [ gtk3 ];
  nativeBuildInputs = with pkgs; [ wrapGAppsHook makeWrapper ];
  propagatedNativeBuildInputs = with pkgs; [
    bc librsvg sassc gdk-pixbuf.dev glib.dev gtk-engine-murrine
  ];

  passthru = {
    pluginName = "theme_oomox";
  };

  dontBuild = true;

  installFlags = [
    "-f Makefile_oomox_plugin"
    "DESTDIR=$(out)"
    "PREFIX="
    "APPDIR="
  ];

  installTargets = "install";

  postPatch = ''
    substituteInPlace ./packaging/bin/* \
      --replace "cd /opt/oomox/ &&" "" \
      --replace "exec ./plugins" "exec $out/plugins"

    substituteInPlace ./change_color.sh \
      --replace "cp -r" "cp -r --no-preserve=mode,timestamps"
  '';

  postInstall = ''
    gappsWrapperArgsHook

    wrapProgram $out/plugins/*/change_color.sh \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${pkgs.lib.makeBinPath propagatedNativeBuildInputs}
  '';

  meta = with pkgs.lib; {
  };
}
