{ pkgs, ... }:

{
  home.packages = [
    pkgs.zotero
  ];

  home.file.".zotero/zotero/default_profile/user.js".text = ''
    user_pref("accessibility.typeaheadfind", false);
    user_pref("browser.tabs.remote.autostart", false);
    user_pref("javascript.options.mem.gc_per_zone", true);
    user_pref("extensions.zotero.attachments.textExtraction.characters", 0);
    user_pref("extensions.zotero.attachments.textExtraction.pages", 0);
    user_pref("extensions.zotero.indexing.maxPages", 0);
    user_pref("extensions.zotero.indexing.maxCharacters", 0);
    user_pref("datareporting.healthreport.uploadEnabled", false);
    user_pref("toolkit.telemetry.enabled", false);
    user_pref("extensions.zotero.parsePDFs", false);
    user_pref("extensions.zotero.sync.auto", false);
    user_pref("extensions.zotero.sync.storage.enabled", false);
    user_pref("extensions.zotero.automaticTags", false);
    user_pref("extensions.zotero.useDataDir", true);
    user_pref("extensions.zotero.dataDir", "/home/user/.local/share/zotero");
  '';

  home.file.".zotero/zotero/profiles.ini".text = ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Name=default_profile
    IsRelative=1
    Path=default_profile
    Default=1
  '';
}

