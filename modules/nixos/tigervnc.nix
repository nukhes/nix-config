_:

{
  nixos.modules.common =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        tigervnc
      ];

      networking.firewall.trustedInterfaces = [ "tailscale0" ];
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

        if command -v polybar-msg >/dev/null 2>&1; then
          polybar-msg cmd restart >/dev/null 2>&1 || true
        fi
        if command -v i3-msg >/dev/null 2>&1; then
          i3-msg restart >/dev/null 2>&1 || true
        fi

        echo "Resolução do x99 ajustada para 1280x800 (ThinkPad X200) na saída $OUTPUT."
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

        if command -v polybar-msg >/dev/null 2>&1; then
          polybar-msg cmd restart >/dev/null 2>&1 || true
        fi
        if command -v i3-msg >/dev/null 2>&1; then
          i3-msg restart >/dev/null 2>&1 || true
        fi

        echo "Resolução do x99 restaurada para 1920x1080 na saída $OUTPUT."
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

        exec ${pkgs.tigervnc}/bin/x0vncserver \
          -display "$DISPLAY" \
          -rfbport 5900 \
          -FrameRate 60 \
          -PollingCycle 16 \
          -CompareFB 2 \
          -MaxProcessorUsage 60 \
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

        TARGET="$SERVER_HOST"
        if ! ping -c 1 -W 1 "$SERVER_HOST" >/dev/null 2>&1; then
          if ping -c 1 -W 1 "$SERVER_IP" >/dev/null 2>&1; then
            TARGET="$SERVER_IP"
          else
            echo "Erro: Servidor x99 não acessível via Tailscale ($SERVER_HOST / $SERVER_IP)."
            exit 1
          fi
        fi

        echo "==> Conectando ao host x99 ($TARGET) via Tailscale..."
        echo "==> Ajustando resolução no x99 para 1280x800 (ThinkPad X200)..."

        ssh -o ConnectTimeout=4 -o BatchMode=yes "$SERVER_USER@$TARGET" "
          x99-res-x200 2>/dev/null || DISPLAY=:0 nvidia-settings --assign CurrentMetaMode=\"HDMI-0: 1920x1080 {ViewPortIn=1280x800, ViewPortOut=1920x1080+0+0}\" 2>/dev/null || true
          systemctl --user start x0vncserver 2>/dev/null || true
        " || echo "Aviso: Pré-configuração via SSH falhou ou timeout, tentando conectar mesmo assim..."

        cleanup() {
          echo ""
          echo "==> Conexão encerrada. Restaurando resolução original no x99 (1920x1080)..."
          ssh -o ConnectTimeout=4 -o BatchMode=yes "$SERVER_USER@$TARGET" "
            x99-res-restore 2>/dev/null || DISPLAY=:0 nvidia-settings --assign CurrentMetaMode=\"HDMI-0: 1920x1080 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}\" 2>/dev/null || true
          " 2>/dev/null || true
          echo "==> Finalizado."
        }
        trap cleanup EXIT INT TERM

        echo "==> Abrindo TigerVNC otimizado em tela cheia para o ThinkPad X200..."
        ${pkgs.tigervnc}/bin/vncviewer \
          -FullScreen=1 \
          -FullscreenSystemKeys=1 \
          -PreferredEncoding=Tight \
          -NoJPEG=1 \
          -CustomCompressLevel=1 \
          -CompressLevel=1 \
          -AutoSelect=0 \
          -RemoteResize=0 \
          -PointerEventInterval=10 \
          -SendClipboard=1 \
          -AcceptClipboard=1 \
          -SendPrimary=1 \
          -SetPrimary=1 \
          "$TARGET::$SERVER_PORT" "$@"
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
        vnc-start = "systemctl --user start x0vncserver";
        vnc-stop = "systemctl --user stop x0vncserver";
        vnc-restart = "systemctl --user restart x0vncserver";
        vnc-status = "systemctl --user status x0vncserver";
        res-x200 = "x99-res-x200";
        res-restore = "x99-res-restore";
      };
    };
}
