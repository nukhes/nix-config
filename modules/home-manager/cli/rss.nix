{ pkgs, ... }:

{
  home.packages = with pkgs; [ html2text ];

  programs.newsboat = {
    enable = true;
    autoReload = true;
    reloadTime = 60;
    browser = "firefox";

    urls = [
      {
        url = "https://www.theguardian.com/world/rss";
        title = "The Guardian - World";
        tags = [
          "world"
          "en"
        ];
      }
      {
        url = "https://feeds.npr.org/1001/rss.xml";
        title = "NPR News";
        tags = [
          "world"
          "en"
        ];
      }
      {
        url = "https://rss.dw.com/rdf/rss-en-all";
        title = "DW World News";
        tags = [
          "world"
          "en"
        ];
      }
      {
        url = "https://www.aljazeera.com/xml/rss/all.xml";
        title = "Al Jazeera English";
        tags = [
          "world"
          "en"
        ];
      }
      {
        url = "https://feeds.propublica.org/propublica/main";
        title = "ProPublica";
        tags = [
          "investigative"
          "en"
        ];
      }
      {
        url = "https://agenciabrasil.ebc.com.br/rss/ultimasnoticias/feed.xml";
        title = "Agência Brasil";
        tags = [
          "brasil"
          "pt"
        ];
      }
      {
        url = "https://apublica.org/feed/";
        title = "Agência Pública";
        tags = [
          "brasil"
          "investigative"
          "pt"
        ];
      }
      {
        url = "https://news.ycombinator.com/rss";
        title = "Hacker News";
        tags = [
          "tech"
          "news"
        ];
      }
      {
        url = "https://lobste.rs/rss";
        title = "Lobsters";
        tags = [
          "tech"
          "dev"
        ];
      }
      {
        url = "https://github.com/trending.atom";
        title = "GitHub Trending";
        tags = [
          "dev"
          "code"
        ];
      }
    ];

    extraConfig = ''
      html-renderer "html2text -utf8 -width 80"
      color listnormal white black
      color listfocus black yellow bold
      bind-key j down
      bind-key k up
    '';
  };
}
