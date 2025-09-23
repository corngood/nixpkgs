{
  lib,
  windows,
}:

windows.mingw_w64.overrideAttrs (old: {
  pname = "w32api";

  configureFlags = [ (lib.enableFeature true "w32api") ];

  buildInputs = [ ];

  passthru = old.passthru or { } // {
    incdir = "/include/w32api/";
    libdir = "/lib/w32api/";
  };

  meta = old.meta // {
    maintainers = [ lib.maintainers.corngood ];
  };
})
