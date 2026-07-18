{ pkgs, ... }:

{
  home.packages = [
    pkgs.zotero
  ];

  home.file.".zotero/zotero/default_profile/prefs.js".text = ''
    user_pref("accessibility.typeaheadfind", false); // Desativa busca ao digitar
    user_pref("browser.tabs.remote.autostart", false); // Economiza RAM em PCs antigos
    user_pref("javascript.options.mem.gc_per_zone", true); // Gerenciamento de memória agressivo
    user_pref("extensions.zotero.attachments.textExtraction.characters", 0); // Desativa extração de texto de PDFs
    user_pref("extensions.zotero.attachments.textExtraction.pages", 0); // Evita uso de CPU em segundo plano
    user_pref("extensions.zotero.indexing.maxPages", 0); // Zera páginas indexadas
    user_pref("extensions.zotero.indexing.maxCharacters", 0); // Desativa indexação de busca interna
    user_pref("datareporting.healthreport.uploadEnabled", false); // Desativa envio de dados
    user_pref("toolkit.telemetry.enabled", false); // Desativa telemetria Mozilla/Zotero
    user_pref("extensions.zotero.parsePDFs", false); // Não tenta ler metadados de PDF na internet automaticamente
    user_pref("extensions.zotero.sync.auto", false); // Sincroniza apenas quando você clicar (evita travamentos)
    user_pref("extensions.zotero.sync.storage.enabled", false); // Desativa download automático de arquivos pesados
    user_pref("extensions.zotero.automaticTags", false); // Não cria tags automáticas baseadas em artigos
  '';

  xdg.configFile."Zotero/Zotero/profiles.ini".text = ''
    [General]
    StartWithLastProfile=1

    [Profile0]
    Name=default
    IsRelative=1
    Path=../../.zotero/zotero/default_profile
    Default=1
  '';
}

