{ lib
, rustPlatform
, cmake
, ninja
, pkg-config
, autoPatchelfHook
, qt6
, llvmPackages
, libjack2
, alsa-lib
, libsndfile
, portaudio
, lilv
, lv2
, zita-resampler
, serd
, sord
, sratom
, glib
, dbus
, libxkbcommon
, wayland
, boost
, libarchive
, cryptsetup
, nlohmann_json
, fmt
, xorg
, libGL
, libGLU
, catch2_3
, lua5_4
, stdenv
, src
}:

let
  # pkgs.qt6.env already includes pkgs.qt6.qtbase
  # And using `with` to prevent a lot of typing.
  qtEnv = with qt6; env "qt-custom-${qtbase.version}" [
    qtdeclarative
    qtwayland
    qt5compat
    qtgraphs
  ];
in
rustPlatform.buildRustPackage {
  pname = "shoopdaloop";
  version = "0.0.1";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  # Native build inputs (tools required at build time)
  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    rustPlatform.bindgenHook
    autoPatchelfHook
    qt6.wrapQtAppsHook
    llvmPackages.libclang
    lua5_4
    qtEnv
  ];

  # Build inputs (libraries required at runtime/link time)
  buildInputs = [
    # Qt
    qtEnv

    # Audio
    libjack2
    alsa-lib
    libsndfile
    portaudio
    lilv
    lv2
    zita-resampler
    serd
    sord
    sratom

    # System
    glib
    dbus
    libxkbcommon
    wayland

    # Libraries
    boost
    libarchive
    cryptsetup
    nlohmann_json
    fmt

    # Graphics/X11
    xorg.libxcb
    xorg.libX11
    xorg.libXi
    xorg.libXrender
    libGL
    libGLU

    # Test
    catch2_3

    # Scripting
    lua5_4
  ];

  env = {
    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
    # cxx-qt needs QMAKE variable to be pointing to qmake.
    QMAKE = "${qtEnv}/bin/qmake";
    qtPluginPrefix = "lib/qt-6/plugins";
    qtQmlPrefix = "lib/qt-6/qml";
  };

  # Enable tests
  doCheck = false;

  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;
  dontUseCmakeBuild = true;
  dontUseNinjaInstall = true;
  dontUseCmakeInstall = true;

  # Manually install the C++ shared library built by build.rs
  postInstall = ''
    mkdir -p $out/lib
    find target -name "libshoopdaloop_backend.so" -exec cp {} $out/lib/ \;

    # Copy assets to bin directory where the executable expects them
    mkdir -p $out/bin
    cp -r src/qml $out/bin/qml
    cp -r src/lua $out/bin/lua
    cp -r src/session_schemas $out/bin/session_schemas
    if [ -d resources ]; then
        cp -r resources $out/bin/resources
    fi

    # Create config file
    cat > $out/bin/shoop-config.toml <<EOF
qml_dir = "$out/bin/qml"
lua_dir = "$out/bin/lua"
resource_dir = "$out/bin/resources"
schemas_dir = "$out/bin/session_schemas"
dynlibpaths = ["$out/lib"]
EOF
  '';

  meta = with lib; {
    description = "Shoopdaloop application";
    homepage = "https://github.com/SanderVocke/shoopdaloop";
    license = licenses.gpl3; # Assuming GPL3 based on LICENSE file size, but should verify
    maintainers = [];
    platforms = platforms.linux;
  };
}
