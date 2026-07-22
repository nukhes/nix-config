{ pkgs, ... }: {
  home.packages = with pkgs; [
    ppsspp-qt
  ];

  xdg.configFile."ppsspp/PSP/SYSTEM/ppsspp.ini" = {
    text = ''
      [Graphics]
      GraphicsBackend = 0 # 0 for Vulkan (best performance), 3 for OpenGL if Vulkan fails
      RenderingMode = 1   # 1 for Skip buffer effects (fastest), 0 for Buffered rendering (needed for some effects)
      FrameSkip = 1       # Skips frames if the system dips
      FrameSkipType = 0   # Skip by number of frames
      AutoFrameSkip = True
      FastMemory = True   # Enables unstable but high-performance memory mapping
      SplineBezierQuality = 0 # 0 for Low quality (boosts speed)
      HardwareTransform = True
      SoftwareSkinning = True
      VertexCache = True
      TextureScalingLevel = 1 # 1 for Off (Auto/Native PSP resolution for max speed)
      AnisotropyLevel = 0     # Off for maximum performance

      [CPU]
      IOTimingMethod = 0  # 0 for Fast (reduces lag), 1 for Host, 2 for Accurate
    '';
  };

  xdg.configFile."ppsspp/PSP/SYSTEM/controls.ini" = {
    text = ''
      [ControlMapping]
      Up = kbd.Up
      Down = kbd.Down
      Left = kbd.Left
      Right = kbd.Right
      Circle = kbd.Z
      Cross = kbd.X
      Square = kbd.C
      Triangle = kbd.V
      Start = kbd.Return
      Select = kbd.Space
      L = kbd.A
      R = kbd.S
      An.Up = kbd.W
      An.Down = kbd.S
      An.Left = kbd.A
      An.Right = kbd.D
    '';
  };
}
