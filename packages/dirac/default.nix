{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  nodejs,
  ripgrep,
}:
buildNpmPackage rec {
  pname = "dirac";
  version = "0.2.92";

  src = fetchurl {
    url = "https://registry.npmjs.org/dirac-cli/-/dirac-cli-${version}.tgz";
    hash = "sha512-l75OrKaqhVLUUS78DYunp1PR4AhigskzOSCddaqnwie9dKHx3YJfBpy2xVhagFb9iy1r2EH1Wshc1lTV4w8uRg==";
  };

  npmDepsHash = "sha256-dxtj4raTm6GyaB+PorGQLsBhPmw50bCVFx4G9hcUvFo=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    jq 'del(.devDependencies)' package.json > package.json.tmp && mv package.json.tmp package.json
  '';

  nativeBuildInputs = [jq];

  dontNpmBuild = true;
  npmInstallFlags = ["--ignore-scripts"];
  npmRebuildFlags = ["--ignore-scripts"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/dirac $out/bin
    cp -r . $out/lib/dirac/
    chmod +x $out/lib/dirac/dist/cli.mjs
    makeWrapper ${lib.getExe nodejs} $out/bin/dirac \
      --add-flags $out/lib/dirac/dist/cli.mjs \
      --prefix PATH : ${lib.makeBinPath [ripgrep]}
    runHook postInstall
  '';

  meta = {
    description = "Token-efficient coding agent CLI using hash-anchored edits and AST manipulation";
    homepage = "https://dirac.run";
    license = lib.licenses.asl20;
    mainProgram = "dirac";
    platforms = with lib.platforms; linux ++ darwin;
  };
}
