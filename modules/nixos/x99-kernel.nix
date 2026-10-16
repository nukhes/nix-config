_:

{
  nixos.modules.x99 = { pkgs, ... }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      kernelPackages = pkgs.linuxPackages_xanmod_stable;

      kernelModules = [
        "coretemp"
        "nct6775"
      ];

      blacklistedKernelModules = [
        "firewire-core"
        "mei_me"
        "mei"
        "lpc_ich"
        "ieee1394"
        "sbp2"
      ];

      # Parâmetros genéricos do host. Os relativos a VFIO/KVM/anti-detecção
      # ficam em x99-vfio.nix.
      kernelParams = [
        "nowatchdog"
        "nmi_watchdog=0"
        "audit=0"
        "transparent_hugepage=always"
        # ─── Nota: mitigations=off já está otimizado. NÃO remover ──────
        # XanMod + mitigations=off dá ~5-15% de performance no ArcGIS.
        # Anti-Cheats NÃO verificam presença de mitigations (é hardware-side).
        "mitigations=off"
        "nvidia-drm.modeset=1"
      ];

      kernel.sysctl = {
        "vm.max_map_count" = 2147483642;
        "fs.file-max" = 2097152;
      };
    };

    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "1048576";
      }
    ];

    time.timeZone = "America/Sao_Paulo";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "pt_BR.UTF-8";
        LC_IDENTIFICATION = "pt_BR.UTF-8";
        LC_MEASUREMENT = "pt_BR.UTF-8";
        LC_MONETARY = "pt_BR.UTF-8";
        LC_NAME = "pt_BR.UTF-8";
        LC_NUMERIC = "pt_BR.UTF-8";
        LC_PAPER = "pt_BR.UTF-8";
        LC_TELEPHONE = "pt_BR.UTF-8";
        LC_TIME = "pt_BR.UTF-8";
      };
    };
  };
}
