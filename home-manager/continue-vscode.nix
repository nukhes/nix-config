{ config, pkgs, ... }:

{
  home.file.".config/continue/config.json".text = builtins.toJSON {
  models = [
    {
      title = "Gemini 3.5 Flash (Default)";
      provider = "gemini";
      model = "gemini-3.5-flash";
      apiKey = "cmd:cat /run/agenix/gemini-key";
    }
    {
      title = "Gemini 3.1 Pro (Heavy Brain)";
      provider = "gemini";
      model = "models/gemini-3.1-pro-preview"; # Usando o path completo se o provider exigir
      apiKey = "cmd:cat /run/agenix/gemini-key";
    }
    {
      title = "Gemini Deep Research (Agêntico)";
      provider = "gemini";
      model = "models/deep-research-preview-04-2026";
      apiKey = "cmd:cat /run/agenix/gemini-key";
    }
  ];

  #tabAutocompleteModel = {
  #  title = "Ollama Local";
  #  provider = "ollama";
  #  model = "qwen2.5-coder:1.5b";
  #};

  customCommands = [
    {
      name = "revisar";
      prompt = "voce eh um desenvolvedor especialista em codigo limpo e eficiente, sua missao eh buscar falhas e erros de logica no codigo enviado, refatore o codigo de modo limpo e eficiente, nao escreva comentarios inuteis, documente as funcoes com ingles escrito em lowercase.";
    }
  ];
  };
  age.secrets.gemini-p052 = {
    file = ../secrets/gemini-p052.age;
    path = "${config.home.homeDirectory}/.config/api-keys/gemini-p052";
    mode = "0600";
  };
}
