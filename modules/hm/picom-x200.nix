{ lib, ... }:

{
  hm.modules.x200 = _: {
    # GMA 4500MHD (GM45) only supports OpenGL 2.1 — picom's glx backend
    # causes black flicker, and even xrender adds overhead for marginal
    # benefit.  Disable the compositor entirely for a rock-solid display.
    services.picom.enable = lib.mkForce false;
  };
}
