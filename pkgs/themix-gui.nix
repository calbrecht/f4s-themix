{ pkgs
, src
, version
, python
# Available plugins (can be overridden)
, availablePlugins
# The withPlugins pattern is copied from mailnag pkg.
# Used in the withPlugins interface at passthru, can be overrided directly, or
# prefarably via e.g: `themix-gui.withPlugins (ps: [ps.theme_oomox ps.etc])`.
, themix-gui
, userPlugins ? []
}:

python.pkgs.buildPythonApplication rec {
  inherit python;
  inherit src;
  inherit version;

  pname = "themix-gui";

  buildInputs = with pkgs; [ gdk-pixbuf gtk3 ];
  nativeBuildInputs = with pkgs; [ gobject-introspection wrapGAppsHook ];
  propagatedBuildInputs = [ python.pkgs.pygobject3 ];

  passthru = {
    inherit availablePlugins;
    withPlugins = filter: themix-gui.override {
      userPlugins = filter availablePlugins;
    };
  };

  format = "other";

  dontBuild = true;

  installFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "APPDIR="
  ];

  installTargets = "install_gui";

  postPatch = ''
    substituteInPlace ./packaging/bin/* \
      --replace "cd /opt/oomox/ &&" "" \
      --replace "python3" "${python.executable}"

    substituteInPlace ./oomox_gui/config.py \
      --replace 'os.path.abspath(os.path.join(SCRIPT_DIR, "../"))' "'$out'"
  '';

  postInstall = ''
    mkdir -p $out/${python.sitePackages}
    mv oomox_gui $out/${python.sitePackages}/

    ${pkgs.lib.concatMapStringsSep "\n" (plugin: ''
      ln -s ${plugin}/plugins/${plugin.pluginName} $out/plugins/${plugin.pluginName}
    '') userPlugins}
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PYTHONPATH : "${python.pkgs.makePythonPath propagatedBuildInputs}"
      --prefix PYTHONPATH : "$out/${python.sitePackages}"
    )
  '';

  meta = with pkgs.lib; {
  };
}
