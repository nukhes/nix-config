{
  config,
  pkgs,
  ...
}:
{
  programs.tmux = {
    enable = true;
    shortcut = "space";
    keyMode = "vi";
    mouse = true;
    historyLimit = 10000;
    terminal = "tmux-256color";

    extraConfig = ''
      unbind C-b
      set -g prefix M-space
      bind M-space send-prefix

      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on

      bind v split-window -h -c "#{pane_current_path}"
      bind h split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -u
      bind -n M-l select-pane -R

      bind -r C-Up resize-pane -U 5
      bind -r C-Down resize-pane -D 5
      bind -r C-Left resize-pane -L 5
      bind -r C-Right resize-pane -R 5

      bind r source-file ~/.config/tmux/tmux.conf \; display "Configuração recarregada!"

      set -s escape-time 0

      set -g status-style bg=default,fg="#cdd6f4"
      set -g status-left ""
      set -g status-right "#[fg=#b4befe,bold]#S "
      setw -g window-status-current-format "#[fg=#1e1e2e,bg=#cba6f7,bold] #I:#W "
      setw -g window-status-format "#[fg=#a6adc8,bg=default] #I:#W "
      set -g pane-border-style fg="#313244"
      set -g pane-active-border-style fg=#b4befe
    '';
  };
}
