{
  config,
  pkgs,
  ...
}: {
  services.picom = {
    enable = true;

    # Aceleração por Hardware e V-Sync (Essencial para fluidez matemática sem screen tearing)
    backend = "glx";
    vSync = true;

    # ==========================================
    # SOMBRAS E PROFUNDIDADE
    # ==========================================
    shadow = true;
    shadowOpacity = 0.4;
    shadowOffsets = [(-15) (-15)]; # Deslocamento calculado para parecer iluminação superior

    # Previne conflitos bloqueando sombras em janelas utilitárias e pop-ups
    shadowExclude = [
      "window_type = 'menu'"
      "window_type = 'dropdown_menu'"
      "window_type = 'popup_menu'"
      "window_type = 'tooltip'"
      "window_type = 'dnd'"
      "class_g = 'i3-frame'" # Remove sombras dos contêineres vazios do i3
      "_GTK_FRAME_EXTENTS@:c" # Previne conflitos de sombra dupla em apps GTK3/4
    ];

    fade = true;
    fadeDelta = 5; # Tempo (ms) entre cada frame do fade
    fadeSteps = [0.03 0.03]; # Velocidade de entrada e saída (Fade-in / Fade-out)
    fadeExclude = [];

    settings = {
      corner-radius = 12;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "class_g = 'i3bar'" # Não arredonda a barra de status do topo
        "class_g = 'dmenu'"
      ];

      # Configuração do Blur (Desfoque dual_kawase para efeito de vidro fosco perfeito)
      blur = {
        method = "dual_kawase";
        strength = 4; # Intensidade do desfoque (cuidado com consumo de GPU)
        background = false;
        background-frame = false;
        background-fixed = false;
      };

      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "window_type = 'tooltip'"
        "class_g = 'slop'"
        "class_g = 'maim'"
        "_GTK_FRAME_EXTENTS@:c"
      ];

      # Detecção inteligente do ambiente de janelas
      detect-client-opacity = true;
      detect-transient = true;
      detect-client-leader = true;
      mark-wmwin-focused = true;
      mark-ovredir-focused = true;
      use-damage = true; # Otimiza uso de CPU desenhando apenas partes da tela que mudaram
    };
  };
}
