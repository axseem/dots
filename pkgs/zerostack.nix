{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "zerostack";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "gi-dellav";
    repo = "zerostack";
    rev = "v1.3.0";
    hash = "sha256-ThJOtVgpaizM3wmLNnJJfZBrTgG1nYoVDeWOEXduPGA=";
  };

  cargoHash = "sha256-k7UAAiGmjG7arGdrog6lpXF7YaVz/42S/njeJ/ev6sE=";

  meta = {
    description = "Minimal coding agent";
    homepage = "https://github.com/gi-dellav/zerostack";
    license = lib.licenses.mit;
    mainProgram = "zerostack";
  };
}
