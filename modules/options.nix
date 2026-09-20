{ lib, ... }:

let
  _ = builtins.trace "EVALUATING options.nix" null;
in
{
  options = {
    nixos.modules = {
      common = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
      };
      hackbook = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
      };
      x99 = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
      };
    };

    hm.modules.common = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
    };

    darwin.modules.common = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
    };
  };
}
