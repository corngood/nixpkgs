{
  buildDotnetModule,
  fetchFromGitHub,
  lib,
}:

let
  src = fetchFromGitHub {
    owner = "FanTranslatorsInternational";
    repo = "Kuriimu2";
    rev = "c40d4a66d620061179530ff8d308fdc6c980b2cc";
    hash = "sha256-JzTEdfCsFdmG48x/cCNji4oIYT7atMG8VgX6uOt3mcA=";
  };

  komponent = buildDotnetModule rec {
    name = "komponent";

    inherit src;

    nugetDeps = ./komponent.deps.json;

    projectFile = [ "src/lib/Komponent" ];

    packNupkg = true;
  };

  kaligraphy = buildDotnetModule rec {
    name = "kaligraphy";

    inherit src;

    nugetDeps = ./kaligraphy.deps.json;

    projectFile = [ "src/lib/Kaligraphy" ];

    buildInputs = [ komponent ];

    packNupkg = true;
  };

  kanvas = buildDotnetModule rec {
    name = "kanvas";

    inherit src;

    nugetDeps = ./kanvas.deps.json;

    projectFile = [ "src/lib/Kanvas" ];

    buildInputs = [ komponent ];

    packNupkg = true;
  };

  kompression = buildDotnetModule rec {
    name = "kompression";

    inherit src;

    nugetDeps = ./kompression.deps.json;

    projectFile = [ "src/lib/Kompression" ];

    buildInputs = [ komponent ];

    packNupkg = true;
  };

in
buildDotnetModule rec {
  name = "kuriimu2";

  src = fetchFromGitHub {
    owner = "FanTranslatorsInternational";
    repo = "Kuriimu2";
    rev = "c40d4a66d620061179530ff8d308fdc6c980b2cc";
    hash = "sha256-JzTEdfCsFdmG48x/cCNji4oIYT7atMG8VgX6uOt3mcA=";
  };

  buildInputs = [
    komponent
    kaligraphy
    kanvas
    kompression
  ];

  nugetDeps = ./deps.json;

  passthru = {
    inherit
      komponent
      kaligraphy
      kanvas
      kompression
      ;
  };

  projectFile = [ "src/ui/Kuriimu2.ImGui" ];
}
