_:

{
  hm.modules.common =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        ouch
        unrar
        sxiv
      ];

      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;

        extraPackages = with pkgs; [
          ouch
          unrar
          sxiv
        ];

        settings = {
          mgr = {
            show_hidden = true;
            sort_by = "alphabetical";
            sort_sensitive = false;
            sort_reverse = false;
            sort_dir_first = true;
          };

          opener = {
            html = [
              {
                run = "firefox %s1";
                orphan = true;
                desc = "Firefox";
              }
            ];
            image = [
              {
                run = "sxiv -a %s";
                orphan = true;
                desc = "sxiv";
              }
            ];
            pdf = [
              {
                run = "zathura %s1";
                orphan = true;
                desc = "Zathura";
              }
            ];
            extract = [
              {
                run = "ouch decompress --yes %s";
                desc = "Extract here with ouch";
              }
            ];
            editor = [
              {
                run = "\${EDITOR:-nvim} %s";
                block = true;
                desc = "$EDITOR";
              }
            ];
          };

          open = {
            prepend_rules = [
              {
                mime = "text/html";
                use = [
                  "html"
                  "editor"
                ];
              }
              {
                mime = "image/*";
                use = "image";
              }
              {
                mime = "application/pdf";
                use = "pdf";
              }
              {
                mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
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
          mgr = {
            prepend_keymap = [
              {
                on = [ "E" ];
                run = "shell -- ouch decompress --yes %s";
                desc = "Extract archive with ouch";
              }
            ];
          };
        };
      };
    };
}
