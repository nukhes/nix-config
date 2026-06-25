{ config, pkgs, ... }:

{

  # 2. Configuração do Polybar
  services.polybar = {
    enable = true;
    
    # Garante que o Polybar seja compilado com suporte nativo ao i3wm
    package = pkgs.polybar.override {
      i3Support = true;
    };
    
    # Script para iniciar a barra (o Home Manager executa isso no login)
    script = ''
      polybar principal &
    '';

    config = {
      "bar/principal" = {
        width = "100%";
        height = "24pt";
        radius = 0;
        
        # Cores (Tema Dark elegante)
        background = "#282A2E";
        foreground = "#C5C8C6";
        
        line-size = "3pt";
        border-size = "0pt";
        padding-left = 1;
        padding-right = 2;
        module-margin = 1;
        
        # Configuração da Iosevka Nerd Font (Índice 0 é a fonte primária, 1 é fallback)
        font-0 = "Iosevka Nerd Font:style=Regular:size=11;2";
        font-1 = "Iosevka Nerd Font:style=Regular:size=14;3"; # Útil para ícones que precisam ser maiores

        # Disposição dos módulos na barra
        modules-left = "i3 xwindow";
        modules-right = "pulseaudio memory cpu date";

        cursor-click = "pointer";
        cursor-scroll = "ns-resize";
        enable-ipc = true;
      };

      # --- Módulos ---

      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        show-urgent = true;
        strip-wsnumbers = true;
        index-sort = true;
        enable-click = true;
        enable-scroll = false;

        label-focused = "%name%";
        label-focused-background = "#373B41";
        label-focused-underline = "#F0C674"; # Amarelo/Dourado indicando foco
        label-focused-padding = 2;

        label-unfocused = "%name%";
        label-unfocused-padding = 2;

        label-urgent = "%name%";
        label-urgent-background = "#A54242"; # Vermelho indicando urgência
        label-urgent-padding = 2;
      };

      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:50:...%";
        label-foreground = "#81A2BE"; # Azul suave para o título da janela
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<ramp-volume> <label-volume>";
        label-volume = "%percentage%%";
        label-muted = "󰖁 mutado";
        label-muted-foreground = "#707880";
        
        # Ícones da Nerd Font para volume
        ramp-volume-0 = "󰕿";
        ramp-volume-1 = "󰖀";
        ramp-volume-2 = "󰕾";
        ramp-volume-foreground = "#B5BD68"; # Verde
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = "󰍛 ";
        format-prefix-foreground = "#B294BB"; # Roxo
        label = "%percentage_used%%";
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = "󰻠 ";
        format-prefix-foreground = "#8ABEB7"; # Ciano
        label = "%percentage%%";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%H:%M";
        date-alt = "%Y-%m-%d %H:%M:%S"; # Mostra data completa ao clicar
        label = "󰃰 %date%";
        label-foreground = "#F0C674"; # Amarelo/Dourado
      };
    };
  };
}