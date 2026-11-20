{ config, ... }:

let
  flakeConfig = config;
in
{
  nixos.modules.x99 =
    { pkgs, ... }:
    let
      inputLeapConf = pkgs.writeText "input-leap.conf" ''
        section: screens
          x99:
          x200:
        end
        section: links
          x99:
            up = x200
          x200:
            down = x99
        end
        section: options
          screenSaverSync = false
        end
      '';

      inputLeapTray = pkgs.writeShellApplication {
        name = "input-leap-tray";
        runtimeInputs = with pkgs; [
          bash
          coreutils
          jq
          systemd
          tailscale
          yad
        ];
        text = ''
          SELF="$0"
          PEER="x200"
          SERVICE="input-leap-server.service"
          POLL_INTERVAL=5

          if [ "''${1:-}" = "toggle" ]; then
            if systemctl --user is-active --quiet "$SERVICE"; then
              systemctl --user stop "$SERVICE"
            else
              systemctl --user start "$SERVICE"
            fi
            if [ -n "''${2:-}" ]; then
              kill -USR1 "$2" 2>/dev/null || true
            fi
            exit 0
          fi

          yad_pid=""
          sleep_pid=""
          last_state=""
          woken=0

          peer_online() {
            tailscale status --json 2>/dev/null \
              | jq -e --arg peer "$PEER" '
                  .Self.Online == true and any(
                    .Peer // {} | .[];
                    (.HostName == $peer or (.DNSName | split(".")[0]) == $peer) and .Online == true
                  )
                ' >/dev/null 2>&1
          }

          service_active() {
            systemctl --user is-active --quiet "$SERVICE"
          }

          stop_tray() {
            if [ -n "$yad_pid" ]; then
              printf 'quit\n' >&3 2>/dev/null || true
              exec 3>&- 2>/dev/null || true
              kill "$yad_pid" 2>/dev/null || true
              wait "$yad_pid" 2>/dev/null || true
              yad_pid=""
            fi
            last_state=""
          }

          start_tray() {
            local fifo init_icon
            fifo="$(mktemp -u "''${XDG_RUNTIME_DIR:-/tmp}/input-leap-tray.XXXXXX")"
            mkfifo "$fifo"
            exec 3<>"$fifo"
            rm -f "$fifo"

            if service_active; then
              init_icon="barrier-connected"
            else
              init_icon="barrier-disconnected"
            fi

            yad --notification \
              --listen \
              --no-middle \
              --image="$init_icon" \
              --separator='|' \
              --item-separator='!' \
              --command="$SELF toggle $$" \
              <&3 3>&- >/dev/null 2>&1 &
            yad_pid=$!
            last_state=""
          }

          sync_tray() {
            local state icon tooltip label menu_icon
            if service_active; then
              state="active"
              icon="barrier-connected"
              tooltip="Input Leap: ativo ($PEER)"
              label="Desligar bypass"
              menu_icon="barrier-disconnected"
            else
              state="inactive"
              icon="barrier-disconnected"
              tooltip="Input Leap: desligado ($PEER)"
              label="Ligar bypass"
              menu_icon="barrier-connected"
            fi

            [ "$state" = "$last_state" ] && return 0

            if ! {
              printf 'icon:%s\n' "$icon"
              printf 'tooltip:%s\n' "$tooltip"
              printf 'menu:%s!%s toggle %s!%s\n' "$label" "$SELF" "$$" "$menu_icon"
            } >&3 2>/dev/null; then
              stop_tray
              return 0
            fi

            last_state="$state"
          }

          cleanup() {
            stop_tray
            [ -n "$sleep_pid" ] && kill "$sleep_pid" 2>/dev/null || true
          }

          wake() {
            woken=1
            [ -n "$sleep_pid" ] && kill "$sleep_pid" 2>/dev/null || true
          }

          trap 'exit 0' INT TERM
          trap cleanup EXIT
          trap wake USR1

          while true; do
            woken=0
            if peer_online; then
              if [ -z "$yad_pid" ] || ! kill -0 "$yad_pid" 2>/dev/null; then
                stop_tray
                start_tray
              fi
              sync_tray
            else
              stop_tray
            fi

            if [ "$woken" -eq 0 ]; then
              sleep "$POLL_INTERVAL" &
              sleep_pid=$!
              wait "$sleep_pid" 2>/dev/null || true
              sleep_pid=""
            fi
          done
        '';
      };

      displayHandler = pkgs.writeShellScript "display-handler" ''
        xrandr="${pkgs.xrandr}/bin/xrandr"
        xset="${pkgs.xset}/bin/xset"

        case "$SRANDRD_EVENT" in
          connected)
            case "$SRANDRD_EDID" in
              E41E0161*) # GWD ARZOPA (necessita modeline CVT-RB para evitar crash)
                if ! $xrandr | ${pkgs.gnugrep}/bin/grep -q "1920x1080_rb"; then
                  $xrandr --newmode "1920x1080_rb" 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync -vsync 2>/dev/null || true
                fi
                $xrandr --addmode "$SRANDRD_OUTPUT" "1920x1080_rb" 2>/dev/null || true
                $xrandr --output "$SRANDRD_OUTPUT" --mode "1920x1080_rb" --auto
                ;;
              *) # Qualquer outro monitor: ativa automaticamente no modo nativo/preferido
                $xrandr --output "$SRANDRD_OUTPUT" --preferred --auto
                ;;
            esac
            $xset dpms force on 2>/dev/null || true
            ;;
          disconnected)
            $xrandr --output "$SRANDRD_OUTPUT" --off 2>/dev/null || true
            ;;
        esac
      '';

      dpmsMouseGuard = pkgs.writers.writePython3 "dpms-mouse-guard" { flakeIgnore = [ "E501" ]; } ''
        import ctypes
        import json
        import os
        import signal
        import sys
        import tempfile
        import threading

        XA_INTEGER = 19
        XI_ALL_DEVICES = 0
        XI_SLAVE_POINTER = 3
        XI_FLOATING_SLAVE = 5
        XI_PROP_MODE_REPLACE = 0
        DPMS_MODE_ON = 0
        SCREEN_SAVER_ON = 1
        POLL_INTERVAL_SECONDS = 0.25

        libX11 = ctypes.cdll.LoadLibrary("${pkgs.libx11}/lib/libX11.so.6")
        libXss = ctypes.cdll.LoadLibrary("${pkgs.libxscrnsaver}/lib/libXss.so.1")
        libXext = ctypes.cdll.LoadLibrary("${pkgs.libxext}/lib/libXext.so.6")
        libXi = ctypes.cdll.LoadLibrary("${pkgs.libxi}/lib/libXi.so.6")


        class XErrorEvent(ctypes.Structure):
            _fields_ = [
                ("type", ctypes.c_int),
                ("display", ctypes.c_void_p),
                ("resourceid", ctypes.c_ulong),
                ("serial", ctypes.c_ulong),
                ("error_code", ctypes.c_ubyte),
                ("request_code", ctypes.c_ubyte),
                ("minor_code", ctypes.c_ubyte),
            ]


        class XScreenSaverInfo(ctypes.Structure):
            _fields_ = [
                ("window", ctypes.c_ulong),
                ("state", ctypes.c_int),
                ("kind", ctypes.c_int),
                ("til_or_since", ctypes.c_ulong),
                ("idle", ctypes.c_ulong),
                ("eventMask", ctypes.c_ulong),
            ]


        class XIAnyClassInfo(ctypes.Structure):
            _fields_ = [("type", ctypes.c_int), ("sourceid", ctypes.c_int)]


        class XIDeviceInfo(ctypes.Structure):
            _fields_ = [
                ("deviceid", ctypes.c_int),
                ("name", ctypes.c_char_p),
                ("use", ctypes.c_int),
                ("attachment", ctypes.c_int),
                ("enabled", ctypes.c_int),
                ("num_classes", ctypes.c_int),
                ("classes", ctypes.POINTER(ctypes.POINTER(XIAnyClassInfo))),
            ]


        XErrorHandler = ctypes.CFUNCTYPE(
            ctypes.c_int, ctypes.c_void_p, ctypes.POINTER(XErrorEvent)
        )

        libX11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        libX11.XOpenDisplay.restype = ctypes.c_void_p
        libX11.XCloseDisplay.argtypes = [ctypes.c_void_p]
        libX11.XCloseDisplay.restype = ctypes.c_int
        libX11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
        libX11.XDefaultRootWindow.restype = ctypes.c_ulong
        libX11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        libX11.XInternAtom.restype = ctypes.c_ulong
        libX11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]
        libX11.XSync.restype = ctypes.c_int
        libX11.XFree.argtypes = [ctypes.c_void_p]
        libX11.XFree.restype = ctypes.c_int
        libX11.XSetErrorHandler.argtypes = [XErrorHandler]
        libX11.XSetErrorHandler.restype = ctypes.c_void_p

        libXss.XScreenSaverQueryExtension.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_int),
        ]
        libXss.XScreenSaverQueryExtension.restype = ctypes.c_int
        libXss.XScreenSaverAllocInfo.argtypes = []
        libXss.XScreenSaverAllocInfo.restype = ctypes.POINTER(XScreenSaverInfo)
        libXss.XScreenSaverQueryInfo.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ulong,
            ctypes.POINTER(XScreenSaverInfo),
        ]
        libXss.XScreenSaverQueryInfo.restype = ctypes.c_int

        libXext.DPMSQueryExtension.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_int),
        ]
        libXext.DPMSQueryExtension.restype = ctypes.c_int
        libXext.DPMSInfo.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint16),
            ctypes.POINTER(ctypes.c_uint8),
        ]
        libXext.DPMSInfo.restype = ctypes.c_int

        libXi.XIQueryDevice.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.POINTER(ctypes.c_int),
        ]
        libXi.XIQueryDevice.restype = ctypes.POINTER(XIDeviceInfo)
        libXi.XIFreeDeviceInfo.argtypes = [ctypes.POINTER(XIDeviceInfo)]
        libXi.XIFreeDeviceInfo.restype = None
        libXi.XIChangeProperty.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_ulong,
            ctypes.c_ulong,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_void_p,
            ctypes.c_int,
        ]
        libXi.XIChangeProperty.restype = None


        def log(message):
            print(f"dpms-mouse-guard: {message}", file=sys.stderr, flush=True)


        def _on_x11_error(_dpy, err_ptr):
            err = err_ptr.contents
            log(
                f"X11 error: code={err.error_code} "
                f"request={err.request_code}.{err.minor_code} "
                f"resource={err.resourceid}"
            )
            return 0


        _X11_ERROR_HANDLER = XErrorHandler(_on_x11_error)


        def get_state_path():
            runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
            if not runtime_dir:
                return None
            return os.path.join(runtime_dir, "dpms-mouse-guard-disabled.json")


        def load_state(state_path):
            if not state_path or not os.path.exists(state_path):
                return {}
            try:
                with open(state_path, "r", encoding="utf-8") as fh:
                    raw = json.load(fh)
                if isinstance(raw, dict):
                    return {int(k): str(v) for k, v in raw.items()}
            except (OSError, ValueError, TypeError) as exc:
                log(f"Ignoring unreadable state file {state_path}: {exc}")
            return {}


        def save_state(state_path, disabled_devices):
            if not state_path:
                return
            if not disabled_devices:
                try:
                    os.unlink(state_path)
                except FileNotFoundError:
                    pass
                except OSError as exc:
                    log(f"Failed to remove state file {state_path}: {exc}")
                return

            state_dir = os.path.dirname(state_path) or "."
            tmp_path = None
            try:
                fd, tmp_path = tempfile.mkstemp(
                    prefix=".dpms-mouse-guard-", suffix=".tmp", dir=state_dir
                )
                with os.fdopen(fd, "w", encoding="utf-8") as fh:
                    json.dump({str(k): v for k, v in disabled_devices.items()}, fh)
                os.replace(tmp_path, state_path)
                tmp_path = None
            except OSError as exc:
                log(f"Failed to persist state file {state_path}: {exc}")
            finally:
                if tmp_path is not None:
                    try:
                        os.unlink(tmp_path)
                    except OSError:
                        pass


        def query_devices(dpy):
            ndevices = ctypes.c_int(0)
            devs = libXi.XIQueryDevice(dpy, XI_ALL_DEVICES, ctypes.byref(ndevices))
            if not devs:
                return []
            try:
                result = []
                for i in range(ndevices.value):
                    dev = devs[i]
                    name = (
                        dev.name.decode("utf-8", errors="ignore") if dev.name else ""
                    )
                    result.append((dev.deviceid, name, dev.use, bool(dev.enabled)))
                return result
            finally:
                libXi.XIFreeDeviceInfo(devs)


        def set_device_enabled(dpy, prop_enabled, device_id, enabled):
            val = ctypes.c_uint8(1 if enabled else 0)
            libXi.XIChangeProperty(
                dpy,
                device_id,
                prop_enabled,
                XA_INTEGER,
                8,
                XI_PROP_MODE_REPLACE,
                ctypes.byref(val),
                1,
            )


        def disable_slave_pointers(dpy, prop_enabled, disabled_devices, state_path):
            to_disable = [
                (dev_id, name)
                for dev_id, name, use, enabled in query_devices(dpy)
                if use == XI_SLAVE_POINTER and enabled and "XTEST" not in name
            ]
            if not to_disable:
                return

            for dev_id, name in to_disable:
                disabled_devices[dev_id] = name
            save_state(state_path, disabled_devices)

            for dev_id, _name in to_disable:
                set_device_enabled(dpy, prop_enabled, dev_id, False)
            libX11.XSync(dpy, 0)

            summary = ", ".join(f"{name} (id={dev_id})" for dev_id, name in to_disable)
            log(f"Disabled pointers: {summary}")


        def restore_disabled_pointers(dpy, prop_enabled, disabled_devices, state_path):
            if not disabled_devices:
                return

            current_by_id = {
                dev_id: (name, use, enabled)
                for dev_id, name, use, enabled in query_devices(dpy)
            }
            restored = []
            for dev_id, expected_name in list(disabled_devices.items()):
                info = current_by_id.get(dev_id)
                if info is None:
                    continue
                name, use, enabled = info
                if enabled or name != expected_name:
                    continue
                if use not in (XI_SLAVE_POINTER, XI_FLOATING_SLAVE):
                    continue
                set_device_enabled(dpy, prop_enabled, dev_id, True)
                restored.append((dev_id, name))

            if restored:
                libX11.XSync(dpy, 0)
                summary = ", ".join(
                    f"{name} (id={dev_id})" for dev_id, name in restored
                )
                log(f"Re-enabled pointers: {summary}")

            disabled_devices.clear()
            save_state(state_path, disabled_devices)


        def is_display_asleep(dpy, root, has_dpms, has_xss, ss_info):
            if has_dpms:
                power_level = ctypes.c_uint16(DPMS_MODE_ON)
                dpms_enabled = ctypes.c_uint8(0)
                if libXext.DPMSInfo(
                    dpy, ctypes.byref(power_level), ctypes.byref(dpms_enabled)
                ):
                    if dpms_enabled.value != 0 and power_level.value != DPMS_MODE_ON:
                        return True

            if has_xss and ss_info:
                if libXss.XScreenSaverQueryInfo(dpy, root, ss_info):
                    if ss_info.contents.state == SCREEN_SAVER_ON:
                        return True

            return False


        def main():
            libX11.XSetErrorHandler(_X11_ERROR_HANDLER)

            display_name = os.environ.get("DISPLAY", ":0").encode("utf-8")
            dpy = libX11.XOpenDisplay(display_name)
            if not dpy:
                raise SystemExit("Cannot open X11 display")

            root = libX11.XDefaultRootWindow(dpy)
            prop_enabled = libX11.XInternAtom(dpy, b"Device Enabled", 0)
            state_path = get_state_path()

            event_base = ctypes.c_int(0)
            error_base = ctypes.c_int(0)
            has_dpms = bool(
                libXext.DPMSQueryExtension(
                    dpy, ctypes.byref(event_base), ctypes.byref(error_base)
                )
            )
            has_xss = bool(
                libXss.XScreenSaverQueryExtension(
                    dpy, ctypes.byref(event_base), ctypes.byref(error_base)
                )
            )
            ss_info = libXss.XScreenSaverAllocInfo() if has_xss else None

            stop_event = threading.Event()

            def handle_signal(_signum, _frame):
                stop_event.set()

            signal.signal(signal.SIGTERM, handle_signal)
            signal.signal(signal.SIGINT, handle_signal)

            disabled_devices = load_state(state_path)
            if disabled_devices:
                log(f"Loaded {len(disabled_devices)} previously disabled pointer(s) from state")

            try:
                while not stop_event.is_set():
                    if is_display_asleep(dpy, root, has_dpms, has_xss, ss_info):
                        disable_slave_pointers(
                            dpy, prop_enabled, disabled_devices, state_path
                        )
                    elif disabled_devices:
                        restore_disabled_pointers(
                            dpy, prop_enabled, disabled_devices, state_path
                        )

                    stop_event.wait(POLL_INTERVAL_SECONDS)
            finally:
                restore_disabled_pointers(
                    dpy, prop_enabled, disabled_devices, state_path
                )
                if ss_info:
                    libX11.XFree(ss_info)
                libX11.XCloseDisplay(dpy)


        if __name__ == "__main__":
            main()
      '';
    in
    {
      imports = [
        ./x99-hardware.pkg.nix
      ];

      home-manager.users.user.imports = [
        flakeConfig.hm.modules.x99
      ];

      systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };

      networking = {
        hostName = "x99";
        networkmanager = {
          enable = true;
          insertNameservers = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };
        firewall.allowedTCPPorts = [ 24800 ];
      };

      environment.systemPackages = [
        pkgs.input-leap
        pkgs.srandrd
      ];

      systemd.user.services = {
        input-leap-server = {
          description = "Input Leap Server";
          after = [
            "network.target"
            "graphical-session.target"
          ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.input-leap}/bin/input-leaps -f --no-tray --disable-crypto --name x99 --config ${inputLeapConf}";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };

        input-leap-tray = {
          description = "Input Leap Tray Toggle (yad)";
          after = [
            "network.target"
            "graphical-session.target"
          ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${inputLeapTray}/bin/input-leap-tray";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };

        srandrd = {
          description = "Simple RandR Daemon (Monitor Hotplug & Wake Handler)";
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.srandrd}/bin/srandrd -n -e ${displayHandler}";
            Restart = "on-failure";
            RestartSec = 1;
          };
        };

        dpms-mouse-guard = {
          description = "Disable pointer devices during DPMS screen sleep so only keyboard wakes monitor";
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${dpmsMouseGuard}";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      };

      services = {
        tailscale.enable = true;

        libinput = {
          enable = true;
          mouse.accelProfile = "flat";
          touchpad.accelProfile = "flat";
        };

        xserver.displayManager.sessionCommands = ''
          ${pkgs.xset}/bin/xset s 600
          ${pkgs.xset}/bin/xset dpms 0 0 600
        '';
      };

      powerManagement.cpuFreqGovernor = "performance";

      # Prevent audio device power saving (fixes crackling/popping)
      boot.extraModprobeConfig = ''
        options snd_hda_intel power_save=0 power_save_controller=N
        options snd_usb_audio nrpacks=1
      '';

      hardware.cpu.intel.updateMicrocode = false;

      # Swap configuration: zram for fast compressed in-memory swap, backed by swapfile on NVMe
      zramSwap = {
        enable = true;
        priority = 100;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 16384;
          priority = 10;
        }
      ];

      system.stateVersion = "26.05";
    };
}
