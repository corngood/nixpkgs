{ stdenv, fetchFromGitHub, makeWrapper, which, coreutils, rrdtool, perl, perlPackages
, python, ruby, jre, nettools, bc
}:

stdenv.mkDerivation rec {
  version = "2.999.6-2";
  name = "munin-${version}";

  src = fetchFromGitHub {
    owner = "munin-monitoring";
    repo = "munin";
    rev = version;
    sha256 = "0iqayc8bmfq30s23fh8f85i9dd9ynrcywbg811n5hr308wgvhpzg";
  };

  buildInputs = [
    makeWrapper
    which
    coreutils
    rrdtool
    nettools
    perl
    python
    ruby
    jre
  ] ++ (with perlPackages; [
    ModuleBuild
    DBDSQLite
    DBI
    HTMLTemplatePro
    HTTPServerSimpleCGIPreFork
    CGI
    IOSocketInet6
    LWPUserAgent
    ListMoreUtils
    LogDispatch
    NetSNMP
    NetSSLeay
    NetServer
    ParallelForkManager
    ParamsValidate
    AlienRRDtool
    URI
    XMLDumper
    # tests
    IOstringy
    TestClass
    TestDifferences
    TestMockModule
    TestMockObject
    TestDeep
    TestLongString
    TestPerlCritic
    FileSlurp
    FileReadBackwards
    XMLParser
    DBDPg
    NetDNS
    NetIP
    XMLLibXML
  ]);

  # TODO: tests are failing http://munin-monitoring.org/ticket/1390#comment:1
  # NOTE: important, test command always exits with 0, think of a way to abort the build once tests pass
  # doCheck = false;

  checkPhase = ''
   export PERL5LIB="$PERL5LIB:${rrdtool}/lib/perl5/site_perl"
   LC_ALL=C make -j1 test 
  '';

  patches = [
    ./preserve_environment.patch
  ];

  preBuild = ''
    # munin hardcodes PATH, we need it to obey $PATH
    sed -i '/ENV{PATH}/d' lib/Munin/Node/Service.pm
    echo ${version} > RELEASE
  '';

  buildPhase = ''
    runHook preBuild
    ./Build.PL "$buildFlags" \
      --install_base=$out
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ./Build install "$buildFlags" \
      --install_base=$out
    runHook postInstall
  '';

  postFixup = ''
    echo "Removing references to /usr/{bin,sbin}/ from munin plugins..."
    find "$out/share/plugins" -type f -print0 | xargs -0 -L1 \
        sed -i -e "s|/usr/bin/||g" -e "s|/usr/sbin/||g" -e "s|\<bc\>|${bc}/bin/bc|g"

    if test -e $out/nix-support/propagated-build-inputs; then
        ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
    fi

    for file in "$out"/bin/munin-*; do
        # don't wrap .jar files
        case "$file" in
            *.jar) continue;;
        esac
        wrapProgram "$file" \
          --set PERL5LIB "$out/lib/perl5:$PERL5LIB"
    done
  '';

  meta = with stdenv.lib; {
    description = "Networked resource monitoring tool";
    longDescription = ''
      Munin is a monitoring tool that surveys all your computers and remembers
      what it saw. It presents all the information in graphs through a web
      interface. Munin can help analyze resource trends and 'what just happened
      to kill our performance?' problems.
    '';
    homepage = http://munin-monitoring.org/;
    license = licenses.gpl2;
    maintainers = [ maintainers.domenkozar maintainers.bjornfor ];
    platforms = platforms.linux;
  };
}
