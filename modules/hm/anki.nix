{ ... }:

{
  hm.modules.common = _: {
    programs.anki = {
      enable = true;
      hideBottomBar = true;
      hideTopBar = true;
      minimalistMode = true;
      reduceMotion = true;
    };
  };
}
