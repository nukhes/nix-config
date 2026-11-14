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
