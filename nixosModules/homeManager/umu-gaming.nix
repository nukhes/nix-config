{ config, pkgs, ... }:

{
    home.packages = with pkgs; [
        umu-launcher
        protonup-qt
        winetricks
    ];
      programs.bash = {
    enable = true; # Garante que o Home Manager gerencie seu shell para carregar a função

    initExtra = ''
      play() {
        if [ -z "$1" ]; then
          echo "Error: Invalid game path."
          echo "Usage: play /path/game.exe [GAMEID]"
          return 1
        fi

        local EXE_PATH
        EXE_PATH=$(realpath "$1")
        local EXE_DIR
        EXE_DIR=$(dirname "$EXE_PATH")
        local EXE_NAME
        EXE_NAME=$(basename "$EXE_PATH" .exe)

        local SAFE_NAME
        SAFE_NAME=$(echo "$EXE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')

        export WINEPREFIX="$HOME/.local/share/umu-prefixes/$SAFE_NAME"
        
        export GAMEID="''${2:-0}"

        mkdir -p "$WINEPREFIX"

        echo "--------------------------------------------------------"
        echo " Running game with UMU-Launcher"
        echo "📂 Binary: $EXE_PATH"
        echo "📦 Prefix:    $WINEPREFIX"
        echo "🆔 GAMEID:     $GAMEID"
        echo "--------------------------------------------------------"

        cd "$EXE_DIR" || return 1
        umu-run "$EXE_PATH"
      }
    '';
  };
}
