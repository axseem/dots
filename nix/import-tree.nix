# Recursively collect modules from a directory tree:
# - regular `.nix` files are modules;
# - a directory containing `default.nix` is one module and is not recursed;
# - everything else (hidden entries and non-Nix files) is ignored.
dir: let
  scan = current:
    if builtins.pathExists (current + "/default.nix")
    then [current]
    else let
      entries = builtins.readDir current;
    in
      builtins.concatMap
      (name: let
        path = current + "/${name}";
        type = entries.${name};
      in
        if builtins.substring 0 1 name == "."
        then []
        else if type == "directory"
        then scan path
        else if type == "regular" && builtins.match ".+\\.nix" name != null
        then [path]
        else [])
      (builtins.attrNames entries);
in {
  imports = scan dir;
}
