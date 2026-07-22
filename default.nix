{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, racket, zeromq }:

let
  racketZeromq = fetchFromGitHub {
    owner = "jeapostrophe";
    repo = "zeromq";
    rev = "d077c8f3a66be546ef2c8d257a680dbda7ce60a0";
    hash = "sha256-CdRbo86/S6v65lS7U7EKr9A7h+YOX+iiMm+er9SYZWY=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "bystrotex";
  version = "10.0";
  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      !(type == "directory" && baseNameOf path == "compiled");
  };

  nativeBuildInputs = [ makeWrapper racket ];
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export PLTCOLLECTS="${racketZeromq}:$PWD:"
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ zeromq ]}"
    raco exe -o bystrotex-bin bystroTeX/bystrotex.rkt
    raco exe -o b2l-bin to-latex/b2l.rkt
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/bystrotex/collects"
    install -m755 bystrotex-bin "$out/bin/.bystrotex-wrapped"
    install -m755 b2l-bin "$out/bin/.b2l-wrapped"
    cp -R bystroTeX "$out/share/bystrotex/collects/bystroTeX"
    cp -R "${racketZeromq}/net" "$out/share/bystrotex/collects/net"

    makeWrapper "$out/bin/.bystrotex-wrapped" "$out/bin/bystrotex" \
      --prefix PATH : "${lib.makeBinPath [ racket ]}" \
      --set PLTCOLLECTS "$out/share/bystrotex/collects:" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ zeromq ]}"
    makeWrapper "$out/bin/.b2l-wrapped" "$out/bin/b2l" \
      --set PLTCOLLECTS "$out/share/bystrotex/collects:" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ zeromq ]}"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -x "$out/bin/bystrotex"
    test -x "$out/bin/b2l"
    env PLTCOLLECTS="$out/share/bystrotex/collects:" \
      LD_LIBRARY_PATH="${lib.makeLibraryPath [ zeromq ]}" \
      ${racket}/bin/racket -e '(require net/zmq)'
    runHook postInstallCheck
  '';

  meta = {
    description = "Tools for writing HTML with LaTeX formulas";
    homepage = "https://github.com/amkhlv/bystrotex-etc";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "bystrotex";
  };
}
