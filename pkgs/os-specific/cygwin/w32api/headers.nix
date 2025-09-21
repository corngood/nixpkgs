{
  lib,
  windows,
}:

windows.mingw_w64_headers.overrideAttrs (old: {
  pname = "w32api-headers";

  configureFlags = [ (lib.enableFeature true "w32api") ];

  passthru = old.passthru or { } // {
    tests = { };
    incdir = "/include/w32api/";
    libdir = "/lib/w32api/";
  };

  meta = old.meta // {
    maintainers = [ lib.maintainers.corngood ];
  };
})
