_:

{
  hm.modules.common =
    { pkgs, ... }:

    let
      balena-etcher = pkgs.stdenv.mkDerivation rec {
        # Last working version
        pname = "balena-etcher";
        version = "1.18.11";
        hash = "0bhpijhwi9dpx1fwx3d564agfgxa485d9j97hkk6fgb8svm3h249";

        src = pkgs.fetchurl {
          url = "https://github.com/balena-io/etcher/releases/download/v${version}/balena-etcher_${version}_amd64.deb";
          sha256 = "${hash}";
        };

        nativeBuildInputs = with pkgs; [
          dpkg
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
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxrender
          libxcb
          libxscrnsaver
          libxtst
        ];

        unpackPhase = ''
          dpkg -x $src .
        '';

        installPhase = ''
          mkdir -p $out/bin $out/opt
          cp -r opt/balenaEtcher $out/opt/
          cp -r usr/share $out/share

          # Fix exec path in desktop file
          substituteInPlace $out/share/applications/balena-etcher.desktop \
            --replace "/opt/balenaEtcher/balena-etcher" "$out/bin/balena-etcher" || true

          ln -s $out/opt/balenaEtcher/balena-etcher $out/bin/balena-etcher
        '';

        postFixup = ''
          wrapProgram $out/bin/balena-etcher \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.libGL ]}" \
            --add-flags "--no-sandbox"
        '';
      };
    in
    {
      home.packages = [ balena-etcher ];
    };
}
