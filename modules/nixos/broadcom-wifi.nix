_:

{
  nixos.modules.hackbook =
    { config, lib, ... }:
    {
      nixpkgs.config.allowInsecurePredicate =
        pkg:
        let
          name = lib.getName pkg;
          version = lib.getVersion pkg;
          fullName = if version == "" then name else "${name}-${version}";
        in
        builtins.elem name [ "broadcom-sta" ]
        || builtins.elem fullName (config.nixpkgs.config.permittedInsecurePackages or [ ]);

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
    };
}
