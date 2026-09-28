_:
{
  nixos.modules.x200 = { config, pkgs, lib, ... }: {
    boot = {
      loader.grub = {
        enable = true;
        device = "/dev/sda";
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_6_1;

      kernelModules = [
        "kvm-intel"
        "coretemp"
        "tp_smapi"
        "thinkpad_acpi"
      ];

      blacklistedKernelModules = [
        "firewire-core"
        "firewire-ohci"
        "pcspkr"
        "snd_pcsp"
      ];

      kernelParams = [
        "mitigations=off"
        "nowatchdog"
        "nmi_watchdog=0"
        "i915.enable_fbc=0"
        "i915.enable_psr=0"
        "i915.enable_dc=0"
        "i915.semaphores=0"
        "i915.powersave=0"
        "acpi_backlight=native"
        "intel_pstate=disable"
        "acpi_osi=Linux"
        "mem_sleep_default=deep"
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vt.global_cursor_default=0"
        "audit=0"
        "transparent_hugepage=madvise"
      ];

      consoleLogLevel = 0;

      kernel.sysctl = {
        "vm.swappiness" = 80;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 3;
        "vm.vfs_cache_pressure" = 150;
        "vm.min_free_kbytes" = 16384;
        "vm.page-cluster" = 0;
        "vm.watermark_boost_factor" = 0;
        "kernel.nmi_watchdog" = 0;
        "kernel.sched_autogroup_enabled" = 1;
        "kernel.printk" = "3 3 3 3";
        "net.core.default_qdisc" = "fq_codel";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };

      extraModprobeConfig = ''
        options tcp_bbr
      '';
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
