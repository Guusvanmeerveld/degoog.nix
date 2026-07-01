{
  lib,
  inputs,
  runCommandLocal,
  bun2nix,
  ...
}:
bun2nix.writeBunApplication rec {
  pname = "degoog";
  version = inputs.degoog.rev;
  src = inputs.degoog;

  buildPhase = ''
    bun run build
  '';

  startScript = ''
    bun run start
  '';

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = runCommandLocal "fetch-degoog-deps" {} ''
      ${lib.getExe bun2nix} --lock-file ${src}/bun.lock --output-file $out
    '';
  };

  meta = {
    description = "Search engine aggregator with a comprehensive plugin/extension system";
    homepage = "https://fccview.github.io/degoog/";
    license = lib.licenses.mit;
  };
}
