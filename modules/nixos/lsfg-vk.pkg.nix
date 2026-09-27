{
  lib,
  stdenv,
  fetchurl,
  zstd,
  autoPatchelfHook,
  makeWrapper,
  qt6,
  vulkan-loader,
  libGL,
  gcc-unwrapped,
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
    gcc-unwrapped.lib
  ];

  unpackPhase = ''
    echo "-- unpackPhase diagnostics --"
    echo "src=$src"
    if command -v file >/dev/null 2>&1; then file "$src" || true; fi
    if command -v hexdump >/dev/null 2>&1; then hexdump -C -n 128 "$src" || true; fi
    if command -v zstd >/dev/null 2>&1; then zstd -l "$src" || true; fi

    magic=$(head -c4 "$src" | od -An -t x1 | tr -d ' \n') || true
    echo "magic=$magic"
    case "$magic" in
      1f8b* ) echo "Detected gzip archive"; tar -xzf "$src" ;;
      28b52ffd* ) echo "Detected zstd archive"; zstd -d < "$src" | tar -xf - ;;
      fd377a58* ) echo "Detected xz archive"; xz -d < "$src" | tar -xf - ;;
      425a68* ) echo "Detected bzip2 archive"; bzip2 -d < "$src" | tar -xf - ;;
      * ) echo "Unknown compression; trying tar autodetect"; tar -xf "$src" || {
            echo "tar autodetect failed, trying zstd then gzip";
            zstd -d < "$src" | tar -xf - || gunzip -c "$src" | tar -xf -;
          } ;;
    esac
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
        if [ -x "$out/bin/lsfg-vk-ui" ]; then
          mv "$out/bin/lsfg-vk-ui" "$out/bin/lsfg-vk-ui.real"
          cat > "$out/bin/lsfg-vk-ui" <<'WRAPPER'
    #!/usr/bin/env sh
    mkdir -p "$HOME/.config/lsfg-vk"
    if [ ! -f "$HOME/.config/lsfg-vk/conf.toml" ]; then
      cat > "$HOME/.config/lsfg-vk/conf.toml" <<'EOF_CONF'
    version = 1

    [global]
    dll = "@OUT@/lib/lossless/Lossless.dll"

    [[game]]
    exe = "games"
    multiplier = 3
    flow_scale = 1.0
    performance_mode = true
    hdr_mode = false
    experimental_present_mode = "fifo"
    EOF_CONF
    fi
    exec "@OUT@/bin/lsfg-vk-ui.real" "$@"
    WRAPPER
          sed -i "s|@OUT@|$out|g" "$out/bin/lsfg-vk-ui"
          chmod +x "$out/bin/lsfg-vk-ui"
        fi
  '';

  meta = with lib; {
    description = "Lossless Scaling Frame Generation for Vulkan";
    homepage = "https://github.com/PancakeTAS/lsfg-vk";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
