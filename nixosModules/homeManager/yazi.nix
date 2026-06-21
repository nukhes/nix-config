{
  config,
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true; # Integração fina com o Shell
    enableZshIntegration = true; # Caso mude de shell no futuro

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "name";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
      };

      opener = {
        image = [
          {
            run = "sxiv -a \"$@\"";
            desc = "Visualizar imagem com sxiv";
            orphan = true; # Permite fechar o Yazi sem fechar o sxiv
          }
        ];

        pdf = [
          {
            run = "zathura \"$1\"";
            desc = "Abrir PDF com Zathura";
            orphan = true;
          }
        ];

        extract = [
          {
            run = "ouch decompress \"$@\"";
            desc = "Extrair arquivo aqui";
          }
        ];

        editor = [
          {
            run = "\${EDITOR:-nvim} \"$@\"";
            block = true; # Trava o Yazi enquanto edita
          }
        ];
      };

      open = {
        rules = [
          {
            mime = "image/*";
            use = "image";
          }

          {
            mime = "application/pdf";
            use = "pdf";
          }

          {
            mime = "application/zip";
            use = "extract";
          }
          {
            mime = "application/x-tar";
            use = "extract";
          }
          {
            mime = "application/x-bzip2";
            use = "extract";
          }
          {
            mime = "application/x-gzip";
            use = "extract";
          }
          {
            mime = "application/x-rar";
            use = "extract";
          }
          {
            mime = "application/x-7z-compressed";
            use = "extract";
          }

          {
            mime = "text/*";
            use = "editor";
          }
        ];
      };
    };

    keymap = {
      manager = {
        prepend_keymap = [
          {
            on = [ "E" ];
            run = "open --use=extract";
            desc = "Extrair arquivo compactado";
          }
        ];
      };
    };
  };
}
