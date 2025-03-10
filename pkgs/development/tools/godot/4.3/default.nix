{
  version = "4.3-stable";
  hash = "sha256-MzElflwXHWLgPtoOIhPLA00xX8eEdQsexZaGIEOzbj0=";
  default = {
    exportTemplatesHash = "sha256-9fENuvVqeQg0nmS5TqjCyTwswR+xAUyVZbaKK7Q3uSI=";
  };
  mono = {
    exportTemplatesHash = "sha256-9fENuvVqeQg0nmS5TqjCyTwswR+xAUyVZbaKK7Q0u000";
    nugetDeps = ./deps.json;
  };
}
