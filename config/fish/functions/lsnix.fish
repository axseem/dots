# shows Nix dependencies in a nix-shell
function lsnix
  if not set -q IN_NIX_SHELL
    echo "Not in a nix shell"
    return 1
  end

  set -l raw_inputs "$buildInputs $nativeBuildInputs $propagatedBuildInputs"
  for path in (string split " " $raw_inputs)
    if string match -q "/nix/store/*" $path
      string replace -r '^/nix/store/[a-z0-9]{32}-' "" $path
    end
  end | sort | uniq
end
