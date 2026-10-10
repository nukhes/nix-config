_:

{
  nixos.modules.common =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        tigervnc
      ];

      networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        checkReversePath = "loose";
        allowedUDPPorts = [ 41641 ];
      };
    };

  nixos.modules.x99 =
    { pkgs, ... }:
    let
      xrandr = "${pkgs.xrandr}/bin/xrandr";

      setX200Resolution = pkgs.writeShellScriptBin "x99-res-x200" ''
        set -euo pipefail
        for f in /run/user/1000/lyxauth "$HOME/.Xauthority"; do
          if [ -r "$f" ]; then
            export XAUTHORITY="$f"
            break
          fi
        done
        export DISPLAY="''${DISPLAY:-:0}"

        OUTPUT=$(${xrandr} --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
        if [ -z "$OUTPUT" ]; then
          OUTPUT="HDMI-0"
        fi

        # Scales X11 desktop buffer to 1280x800 (native ThinkPad X200) while keeping 1920x1080 display timing
        if command -v nvidia-settings >/dev/null 2>&1; then
          nvidia-settings --assign CurrentMetaMode="$OUTPUT: 1920x1080 {ViewPortIn=1280x800, ViewPortOut=1920x1080+0+0}" >/dev/null 2>&1 || true
        else
          ${xrandr} --output "$OUTPUT" --mode 1280x800 >/dev/null 2>&1 || true
        fi

        # Temporarily stop picom compositor to eliminate fade transitions,
        # blur calculations, and multiple redraw frames over VNC
        if systemctl --user is-active --quiet picom 2>/dev/null; then
          systemctl --user stop picom 2>/dev/null || true
        fi

        if command -v polybar-msg >/dev/null 2>&1; then
          polybar-msg cmd restart >/dev/null 2>&1 || true
        fi
        if command -v i3-msg >/dev/null 2>&1; then
          i3-msg restart >/dev/null 2>&1 || true
        fi

        echo "Resolução do x99 ajustada para 1280x800 (ThinkPad X200) na saída $OUTPUT (picom pausado)."
      '';

      restoreResolution = pkgs.writeShellScriptBin "x99-res-restore" ''
        set -euo pipefail
        for f in /run/user/1000/lyxauth "$HOME/.Xauthority"; do
          if [ -r "$f" ]; then
            export XAUTHORITY="$f"
            break
          fi
        done
        export DISPLAY="''${DISPLAY:-:0}"

        OUTPUT=$(${xrandr} --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
        if [ -z "$OUTPUT" ]; then
          OUTPUT="HDMI-0"
        fi

        if command -v nvidia-settings >/dev/null 2>&1; then
          nvidia-settings --assign CurrentMetaMode="$OUTPUT: 1920x1080 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}" >/dev/null 2>&1 || true
        else
          ${xrandr} --output "$OUTPUT" --preferred >/dev/null 2>&1 || true
        fi

        # Restore picom compositor for local desktop use
        systemctl --user start picom 2>/dev/null || true

        if command -v polybar-msg >/dev/null 2>&1; then
          polybar-msg cmd restart >/dev/null 2>&1 || true
        fi
        if command -v i3-msg >/dev/null 2>&1; then
          i3-msg restart >/dev/null 2>&1 || true
        fi

        echo "Resolução do x99 restaurada para 1920x1080 na saída $OUTPUT (picom restaurado)."
      '';

      x0vncserverRunner = pkgs.writeShellScript "x0vncserver-run" ''
        set -euo pipefail
        for f in /run/user/1000/lyxauth "$HOME/.Xauthority"; do
          if [ -r "$f" ]; then
            export XAUTHORITY="$f"
            break
          fi
        done
        export DISPLAY="''${DISPLAY:-:0}"

        SECURITY_ARGS=()
        if [ -f "$HOME/.vnc/passwd" ]; then
          SECURITY_ARGS+=("-PasswordFile" "$HOME/.vnc/passwd" "-SecurityTypes" "VncAuth,TLSVnc")
        else
          SECURITY_ARGS+=("-SecurityTypes" "None")
        fi

        # Optimized for responsive remote navigation and low bandwidth:
        # - FrameRate 30: Prevents network bufferbloat on limited connections
        # - PollingCycle 30: 30ms cycle reduces CPU scraping load and coalesces redraws
        # - CompareFB 1: Always check for real pixel changes to avoid redundant transfers
        # - MaxProcessorUsage 50: Bounds CPU consumption
        exec ${pkgs.tigervnc}/bin/x0vncserver \
          -display "$DISPLAY" \
          -rfbport 5900 \
          -FrameRate 30 \
          -PollingCycle 30 \
          -CompareFB 1 \
          -MaxProcessorUsage 50 \
          -AcceptCutText=1 \
          -SendCutText=1 \
          -SendPrimary=1 \
          -SetPrimary=1 \
          "''${SECURITY_ARGS[@]}"
      '';
    in
    {
      environment.systemPackages = [
        setX200Resolution
        restoreResolution
      ];

      systemd.user.services.x0vncserver = {
        description = "TigerVNC server for X display :0 (x0vncserver)";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${x0vncserverRunner}";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };

  hm.modules.common =
    { pkgs, ... }:
    let
      x99Connect = pkgs.writeShellScriptBin "x99-vnc" ''
        set -euo pipefail

        SERVER_HOST="x99"
        SERVER_IP="100.85.133.21"
        SERVER_PORT="5900"
        SERVER_USER="user"

        MODE="balanced"
        EXTRA_ARGS=()

        while [ $# -gt 0 ]; do
          case "$1" in
            --low-bw|--turbo|-l)
              MODE="low-bw"
              shift
              ;;
            --lan|--hq)
              MODE="lan"
              shift
              ;;
            --auto)
              MODE="auto"
              shift
              ;;
            --help|-h)
              echo "Uso: x99-vnc [MODO] [OPÇÕES]"
              echo ""
              echo "Modos de conexão otimizados para ThinkPad X200:"
              echo "  (padrão)           Otimizado para conexões limitadas (Tight + JPEG q6, compressão zlib 6)"
              echo "  --low-bw, --turbo  Modo ultra-econômico (256 cores, JPEG q3, compressão zlib 8, ideal para 3G/hotspot)"
              echo "  --lan, --hq        Modo alta fidelidade para rede local (JPEG q8, compressão zlib 3)"
              echo "  --auto             Modo com seleção automática de velocidade pelo TigerVNC"
              echo ""
              echo "Teclas de atalho no TigerVNC:"
              echo "  F8                 Menu de opções do TigerVNC"
              echo "  Ctrl+Alt           Libera a captura do teclado para o sistema local"
              echo "  Ctrl+Alt+F         Alterna tela cheia"
              exit 0
              ;;
            *)
              EXTRA_ARGS+=("$1")
              shift
              ;;
          esac
        done

        TARGET="$SERVER_HOST"
        if ! ping -c 1 -W 1 "$SERVER_HOST" >/dev/null 2>&1; then
          if ping -c 1 -W 1 "$SERVER_IP" >/dev/null 2>&1; then
            TARGET="$SERVER_IP"
          else
            echo "Erro: Servidor x99 não acessível via Tailscale ($SERVER_HOST / $SERVER_IP)."
            exit 1
          fi
        fi

        echo "==> Conectando ao host x99 ($TARGET) via Tailscale (Modo: $MODE)..."
        echo "==> Ajustando resolução no x99 para 1280x800 e pausando compositor picom..."

        ssh -o ConnectTimeout=4 -o BatchMode=yes "$SERVER_USER@$TARGET" "
          x99-res-x200 2>/dev/null || DISPLAY=:0 nvidia-settings --assign CurrentMetaMode=\"HDMI-0: 1920x1080 {ViewPortIn=1280x800, ViewPortOut=1920x1080+0+0}\" 2>/dev/null || true
          systemctl --user stop picom 2>/dev/null || true
          systemctl --user start x0vncserver 2>/dev/null || true
        " || echo "Aviso: Pré-configuração via SSH falhou ou timeout, tentando conectar mesmo assim..."

        cleanup() {
          echo ""
          echo "==> Conexão encerrada. Restaurando resolução original no x99 (1920x1080) e compositor..."
          ssh -o ConnectTimeout=4 -o BatchMode=yes "$SERVER_USER@$TARGET" "
            x99-res-restore 2>/dev/null || DISPLAY=:0 nvidia-settings --assign CurrentMetaMode=\"HDMI-0: 1920x1080 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}\" 2>/dev/null || true
            systemctl --user start picom 2>/dev/null || true
          " 2>/dev/null || true
          echo "==> Finalizado."
        }
        trap cleanup EXIT INT TERM

        VNC_PARAMS=(
          "-FullScreen=1"
          "-FullscreenSystemKeys=1"
          "-RemoteResize=0"
          "-SendClipboard=1"
          "-AcceptClipboard=1"
          "-SendPrimary=1"
          "-SetPrimary=1"
        )

        case "$MODE" in
          low-bw)
            echo "==> Ativando modo ultra-econômico (JPEG q3, Compress 8, 256 cores)..."
            VNC_PARAMS+=(
              "-PreferredEncoding=Tight"
              "-NoJPEG=0"
              "-QualityLevel=3"
              "-CustomCompressLevel=1"
              "-CompressLevel=8"
              "-AutoSelect=0"
              "-LowColorLevel=2"
              "-PointerEventInterval=30"
            )
            ;;
          lan)
            echo "==> Ativando modo rede local / alta fidelidade (JPEG q8, Compress 3)..."
            VNC_PARAMS+=(
              "-PreferredEncoding=Tight"
              "-NoJPEG=0"
              "-QualityLevel=8"
              "-CustomCompressLevel=1"
              "-CompressLevel=3"
              "-AutoSelect=0"
              "-PointerEventInterval=17"
            )
            ;;
          auto)
            echo "==> Ativando seleção automática de velocidade pelo TigerVNC..."
            VNC_PARAMS+=(
              "-AutoSelect=1"
              "-PointerEventInterval=20"
            )
            ;;
          balanced|*)
            echo "==> Ativando modo otimizado para navegação fluida em conexões limitadas (Tight + JPEG q6, Compress 6)..."
            VNC_PARAMS+=(
              "-PreferredEncoding=Tight"
              "-NoJPEG=0"
              "-QualityLevel=6"
              "-CustomCompressLevel=1"
              "-CompressLevel=6"
              "-AutoSelect=0"
              "-PointerEventInterval=20"
            )
            ;;
        esac

        if [ -f "$HOME/.vnc/passwd" ]; then
          VNC_PARAMS+=("-PasswordFile" "$HOME/.vnc/passwd")
        fi

        echo "==> Abrindo TigerVNC no ThinkPad X200..."
        ${pkgs.tigervnc}/bin/vncviewer \
          "''${VNC_PARAMS[@]}" \
          "''${EXTRA_ARGS[@]}" \
          "$TARGET::$SERVER_PORT"
      '';

      vncX99 = pkgs.writeShellScriptBin "vnc-x99" ''
        exec ${x99Connect}/bin/x99-vnc "$@"
      '';
    in
    {
      home.packages = [
        x99Connect
        vncX99
      ];

      home.shellAliases = {
        vnc-x99 = "x99-vnc";
        x99-vnc = "x99-vnc";
        vnc-x99-low = "x99-vnc --low-bw";
        x99-vnc-low = "x99-vnc --low-bw";
        vnc-x99-lan = "x99-vnc --lan";
        x99-vnc-lan = "x99-vnc --lan";
        vnc-start = "systemctl --user start x0vncserver";
        vnc-stop = "systemctl --user stop x0vncserver";
        vnc-restart = "systemctl --user restart x0vncserver";
        vnc-status = "systemctl --user status x0vncserver";
        res-x200 = "x99-res-x200";
        res-restore = "x99-res-restore";
      };
    };
}
