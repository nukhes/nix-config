{
  config,
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

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
            desc = "view image with sxiv";
            orphan = true;
          }
        ];

        pdf = [
          {
            run = "zathura \"$1\"";
            desc = "read pdf with zathura";
            orphan = true
          }
        ];

        extract = [
          {
            run = "ouch decompress --yes \"$@\"";
            desc = "extract file here";
          }
        ];

        editor = [
          {
            run = "\${EDITOR:-nvim} \"$@\"";
            block = true;
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
            desc = "extract a file";
          }
        ];
      };
    };
  };
}
