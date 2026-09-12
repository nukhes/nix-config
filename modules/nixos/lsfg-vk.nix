{ lib
, stdenv
, fetchurl
, zstd
, autoPatchelfHook
, makeWrapper
, qt6
, vulkan-loader
, libGL
, gcc-unwrapped
}:

stdenv.mkDerivation rec {
  pname = "lsfg-vk";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/PancakeTAS/lsfg-vk/releases/download/v${version}/lsfg-vk-${version}.x86_64.tar.zst";
    hash = "sha256-fjHW852icfvFCuihsJLLh0vGZkdl1bc1nTiXAFf1/P8=";
  };

  dllSrc = fetchurl {
    url = "https://files.catbox.moe/ppy9g5.dll";
    hash = "sha256-2L3jnkj36hKtPnCTVNPDIdPkcOpNthfj/GS/C+yzzUM=";
  };

  nativeBuildInputs = [
    zstd
    autoPatchelfHook
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    vulkan-loader
    libGL
    gcc-unwrapped.lib # Para libstdc++.so.6
  ];

  unpackPhase = ''
    tar --use-compress-program=unzstd -xf $src
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    if [ -d "usr" ]; then
      cp -r usr/* $out/
    else
      cp -r bin lib share $out/
    fi

    mkdir -p $out/lib/lossless
    cp ${dllSrc} $out/lib/lossless/Lossless.dll

    substituteInPlace $out/share/vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json \
      --replace '"library_path": "liblsfg-vk.so"' '"library_path": "'$out'/lib/liblsfg-vk.so"'

    substituteInPlace $out/share/applications/lsfg-vk-ui.desktop \
      --replace 'Exec=lsfg-vk-ui' "Exec=$out/bin/lsfg-vk-ui" \
      --replace 'Icon=gay.pancake.lsfg-vk-ui' "Icon=$out/share/icons/hicolor/256x256/apps/gay.pancake.lsfg-vk-ui.png"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/lsfg-vk-ui \
      --run 'mkdir -p ~/.config/lsfg-vk' \
      --run 'if [ ! -f ~/.config/lsfg-vk/conf.toml ]; then
        cat > ~/.config/lsfg-vk/conf.toml <<EOF
version = 1

[global]
dll = "'$out'/lib/lossless/Lossless.dll"

[[game]]
exe = "games"
multiplier = 3
flow_scale = 1.0
performance_mode = true
hdr_mode = false
experimental_present_mode = "fifo"
EOF
      fi'
  '';

  meta = with lib; {
    description = "Lossless Scaling Frame Generation for Vulkan";
    homepage = "https://github.com/PancakeTAS/lsfg-vk";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
