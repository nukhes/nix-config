{ lib, ... }:

{
  hm.modules.x200 = _: {
    programs.firefox.profiles.default-profile.settings = {
      # GM45 (GMA 4500MHD) only supports OpenGL 2.1 — WebRender and
      # forced GPU compositing cause rendering glitches on this hardware.
      "gfx.webrender.all" = lib.mkForce false;
      "layers.acceleration.force-enabled" = lib.mkForce false;

      # Use software rendering backend
      "gfx.webrender.software" = true;

      # Reduce GPU memory pressure on 256MB shared VRAM
      "gfx.canvas.accelerated" = false;
      "gfx.canvas.accelerated.cache-size" = lib.mkForce 0;
    };
  };
}
