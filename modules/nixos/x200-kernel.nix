_:

{
  nixos.modules.x200 = { pkgs, lib, ... }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      # Latest stable kernel — good Core 2 Duo support without xanmod overhead
      kernelPackages = pkgs.linuxPackages_latest;

      kernelModules = [
        "kvm-intel"
        "coretemp"     # CPU temperature monitoring
        "thinkpad_acpi" # ThinkPad hotkeys, LEDs, fan control
        "tp_smapi"      # Extended battery/charging control
      ];

      extraModulePackages = with pkgs.linuxPackages_latest; [
        tp_smapi  # ThinkPad SMAPI for battery thresholds
      ];

      blacklistedKernelModules = [
        "firewire-core"  # No FireWire on X200
        "firewire-ohci"
        "pcspkr"         # Kill the PC speaker beep
        "snd_pcsp"
      ];

      kernelParams = [
        # -- Security mitigations off for raw performance --
        "mitigations=off"

        # -- Disable watchdogs --
        "nowatchdog"
        "nmi_watchdog=0"

        # -- Intel GPU --
        "i915.modeset=1"
        "i915.enable_fbc=1"       # Framebuffer compression (saves power + bandwidth)
        "i915.enable_psr=0"       # PSR is broken on GM45, disable it
        "i915.fastboot=1"         # Skip unnecessary mode-sets on boot
        "i915.semaphores=1"       # Hardware semaphores for better GPU scheduling

        # -- Power/ACPI --
        "intel_pstate=disable"    # C2D doesn't support pstate; use acpi-cpufreq
        "acpi_osi=Linux"
        "pcie_aspm=force"         # Force ASPM for PCIe power savings
        "mem_sleep_default=deep"  # Deep S3 sleep

        # -- Quiet boot --
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vt.global_cursor_default=0"

        # -- Misc perf --
        "audit=0"
        "transparent_hugepage=madvise"
      ];

      consoleLogLevel = 0;

      kernel.sysctl = {
        # -- Memory management for low-RAM system --
        "vm.swappiness" = 80;                  # Aggressively use zram swap
        "vm.dirty_ratio" = 10;                  # Flush writes sooner (less RAM pressure)
        "vm.dirty_background_ratio" = 3;        # Start background writeback early
        "vm.vfs_cache_pressure" = 150;          # Reclaim dentries/inodes aggressively
        "vm.min_free_kbytes" = 16384;           # Keep 16MB free to avoid OOM stalls
        "vm.page-cluster" = 0;                  # Read single pages from swap (zram is fast)
        "vm.watermark_boost_factor" = 0;        # Disable watermark boosting

        # -- Kernel --
        "kernel.nmi_watchdog" = 0;
        "kernel.sched_autogroup_enabled" = 1;   # Better interactive responsiveness
        "kernel.printk" = "3 3 3 3";

        # -- Network --
        "net.core.default_qdisc" = "fq_codel";
        "net.ipv4.tcp_congestion_control" = "bbr";  # Better TCP throughput
      };

      # -- Load BBR TCP congestion control --
      extraModprobeConfig = ''
        options tcp_bbr
      '';
    };

    # -- File descriptor limits --
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
