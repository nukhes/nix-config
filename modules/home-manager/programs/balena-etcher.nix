{ pkgs, ... }:

let
  balena-etcher = pkgs.stdenv.mkDerivation rec {
    pname = "balena-etcher";
    version = "2.1.6";

    src = pkgs.fetchurl {
      url = "https://github.com${version}/balenaEtcher-linux-x64-${version}.zip";
      sha256 = "sha256-4YtYwRzI7Y40GAs9XNqbyHw+6G7rN9e8v5Xw4Xw4Xw4=";
    };

    nativeBuildInputs = with pkgs; [
      unzip
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      nspr
      nss
      glib
      gtk3
      atk
      cairo
      pango
      alsa-lib
      libdrm
      mesa
      cups
      systemd
      libuuid
      at-spi2-core
      libxshmfence
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libXrender
      xorg.libxcb
      xorg.libXScrnSaver
      xorg.libXtst
    ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/bin $out/opt/balena-etcher

      # Copia todo o conteúdo extraído para a pasta opt
      cp -r balenaEtcher-linux-x64/* $out/opt/balena-etcher/

      # Cria o link simbólico corrigido na pasta bin do sistema
      ln -s $out/opt/balena-etcher/balena-etcher $out/bin/balena-etcher
    '';

    postFixup = ''
      wrapProgram $out/bin/balena-etcher \
        --add-flags "--no-sandbox"
    '';
  };
in
{
  home.packages = [ balena-etcher ];
}
