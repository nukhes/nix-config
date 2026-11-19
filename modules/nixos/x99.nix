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
      '';

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
        import os
        import signal
        import time

        libX11 = ctypes.cdll.LoadLibrary("${pkgs.libx11}/lib/libX11.so.6")
        libXss = ctypes.cdll.LoadLibrary("${pkgs.libxscrnsaver}/lib/libXss.so.1")
        libXext = ctypes.cdll.LoadLibrary("${pkgs.libxext}/lib/libXext.so.6")
        libXi = ctypes.cdll.LoadLibrary("${pkgs.libxi}/lib/libXi.so.6")


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


        libX11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        libX11.XOpenDisplay.restype = ctypes.c_void_p
        libX11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
        libX11.XDefaultRootWindow.restype = ctypes.c_ulong
        libX11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        libX11.XInternAtom.restype = ctypes.c_ulong
        libX11.XFlush.argtypes = [ctypes.c_void_p]

        libXss.XScreenSaverAllocInfo.restype = ctypes.POINTER(XScreenSaverInfo)
        libXss.XScreenSaverQueryInfo.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ulong,
            ctypes.POINTER(XScreenSaverInfo),
        ]

        libXext.DPMSInfo.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint16),
            ctypes.POINTER(ctypes.c_uint8),
        ]

        libXi.XIQueryDevice.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.POINTER(ctypes.c_int),
        ]
        libXi.XIQueryDevice.restype = ctypes.POINTER(XIDeviceInfo)
        libXi.XIFreeDeviceInfo.argtypes = [ctypes.POINTER(XIDeviceInfo)]
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


        def set_slave_pointers(dpy, prop_enabled, enable):
            ndevices = ctypes.c_int()
            devs = libXi.XIQueryDevice(dpy, 0, ctypes.byref(ndevices))
            if not devs:
                return
            val = ctypes.c_uint8(1 if enable else 0)
            for i in range(ndevices.value):
                d = devs[i]
                name = d.name.decode("utf-8", errors="ignore") if d.name else ""
                if d.use == 3 and "XTEST" not in name:
                    if bool(d.enabled) != enable:
                        libXi.XIChangeProperty(
                            dpy,
                            d.deviceid,
                            prop_enabled,
                            19,
                            8,
                            0,
                            ctypes.byref(val),
                            1,
                        )
            libXi.XIFreeDeviceInfo(devs)
            libX11.XFlush(dpy)


        def main():
            display_name = os.environ.get("DISPLAY", ":0").encode("utf-8")
            dpy = libX11.XOpenDisplay(display_name)
            if not dpy:
                raise SystemExit("Cannot open X11 display")

            root = libX11.XDefaultRootWindow(dpy)
            info = libXss.XScreenSaverAllocInfo()
            prop_enabled = libX11.XInternAtom(dpy, b"Device Enabled", 0)

            def restore_and_exit(*_args):
                set_slave_pointers(dpy, prop_enabled, True)
                raise SystemExit(0)

            signal.signal(signal.SIGTERM, restore_and_exit)
            signal.signal(signal.SIGINT, restore_and_exit)

            power_level = ctypes.c_uint16()
            dpms_state = ctypes.c_uint8()
            pointers_disabled = False

            try:
                while True:
                    libXext.DPMSInfo(
                        dpy, ctypes.byref(power_level), ctypes.byref(dpms_state)
                    )
                    libXss.XScreenSaverQueryInfo(dpy, root, info)

                    asleep = (dpms_state.value != 0 and power_level.value != 0) or (
                        info.contents.state == 1
                    )

                    if asleep:
                        set_slave_pointers(dpy, prop_enabled, False)
                        pointers_disabled = True
                    elif pointers_disabled:
                        set_slave_pointers(dpy, prop_enabled, True)
                        pointers_disabled = False

                    time.sleep(0.25)
            finally:
                set_slave_pointers(dpy, prop_enabled, True)


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
            Restart = "always";
            RestartSec = 1;
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
