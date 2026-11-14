_:

let
  ublockLiteId = "ddkjiahejlhfcafbddmgiahcphecmpfh";
  webStoreUpdateUrl = "https://clients2.google.com/service/update2/crx";
in
{
  nixos.modules.common = _: {
    programs.chromium = {
      enable = true;
      homepageLocation = "about:blank";

      extensions = [
        "${ublockLiteId};${webStoreUpdateUrl}"
      ];

      extraOpts = {
        # Aba nova e inicializacao limpas
        NewTabPageLocation = "about:blank";
        HomepageIsNewTabPage = true;
        RestoreOnStartup = 5;
        ShowHomeButton = false;
        BookmarkBarEnabled = false;
        NTPCardsVisible = false;
        NTPMiddleSlotAnnouncementVisible = false;
        PromotionsEnabled = false;
        DefaultBrowserSettingEnabled = false;

        # Desativar anuncios, Privacy Sandbox e telemetria da Google
        PrivacySandboxPromptEnabled = false;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;
        PrivacySandboxAdMeasurementEnabled = false;
        ShoppingListEnabled = false;
        MetricsReportingEnabled = false;
        UrlKeyedAnonymizedDataCollectionEnabled = false;
        FeedbackSurveysEnabled = false;
        ChromeVariations = 2;

        # Desativar IA, Gemini, Lens e modelos locais em background
        GenAiDefaultSettings = 2;
        GeminiSettings = 1;
        AIModeSettings = 1;
        HelpMeWriteSettings = 2;
        HistorySearchSettings = 2;
        TabCompareSettings = 2;
        DevToolsGenAiSettings = 2;
        GenAILocalFoundationalModelSettings = 1;
        LensOverlaySettings = 1;

        # Desativar login/sync, senhas, autofill e bloat
        BrowserSignin = 0;
        SyncDisabled = true;
        PasswordManagerEnabled = false;
        PasswordSharingEnabled = false;
        PasswordLeakDetectionEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        PaymentMethodQueryEnabled = false;
        TranslateEnabled = false;
        SpellCheckServiceEnabled = false;
        SearchSuggestEnabled = false;
        NetworkPredictionOptions = 2;
        HttpsUpgradesEnabled = true;
        BlockThirdPartyCookies = true;
        BackgroundModeEnabled = false;
        HardwareAccelerationModeEnabled = true;
        MediaRecommendationsEnabled = false;
        SideSearchEnabled = false;

        # uBlock Origin Lite: instalado, fixado na barra e em modo completo por padrao
        ExtensionSettings = {
          ${ublockLiteId} = {
            installation_mode = "force_installed";
            update_url = webStoreUpdateUrl;
            toolbar_pin = "force_pinned";
          };
        };

        "3rdparty" = {
          extensions = {
            ${ublockLiteId} = {
              defaultFiltering = "complete";
            };
          };
        };
      };
    };
  };

  hm.modules.common =
    { pkgs, lib, ... }:
    {
      programs.google-chrome = {
        enable = true;

        # No Linux, extensoes sao gerenciadas via politicas (/etc/opt/chrome/policies/managed)
        extensions = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          { id = ublockLiteId; }
        ];

        commandLineArgs = [
          "--no-first-run"
          "--no-default-browser-check"
          "--disable-search-engine-choice-screen"
          "--disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationTargetPrediction,OptimizationHints,Translate,PrivacySandboxSettings4,LensOverlay"
        ];
      };
    };
}
