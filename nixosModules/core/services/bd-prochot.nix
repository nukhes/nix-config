{ config, pkgs, ... }:

{
  boot.kernelModules = [ "msr" ];

  systemd.services.disable-bd-prochot = {
    description = "Disable BD PROCHOT safely by flipping bit 0";
    wantedBy = [ "multi-user.target" ];
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];

    path = [
      pkgs.msr-tools
      pkgs.bash
    ];

    script = ''
      CURRENT_MSR=$(rdmsr 0x1FC)
      NEW_MSR=$(printf '%x\n' $(( 16#$CURRENT_MSR & ~1 )))
      wrmsr 0x1FC "0x$NEW_MSR"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
