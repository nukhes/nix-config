{
  config,
  lib,
  inputs,
  ...
}:

{
  nixpkgs.config.allowInsecurePredicate = pkg: builtins.elem (lib.getName pkg) [ "broadcom-sta" ];

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    blacklistedKernelModules = [
      "b43"
      "bcma"
      "ssb"
      "brcmsmac"
      "intel_pch_thermal"
      "intel_rapl_msr"
      "intel_rapl_common"
      "intel_powerclamp"
      "thunderbolt"
    ];
    kernelModules = [
      "wl"
      "applesmc"
      "coretemp"
    ];
  };
}
