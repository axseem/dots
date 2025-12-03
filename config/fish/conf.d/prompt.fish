set -g fish_greeting

function fish_prompt
  set -l last_status $status
  
  set_color red
  echo -n (prompt_pwd)
  set_color normal

  set_color magenta
  echo -n (fish_git_prompt)
  set_color normal

  if set -q IN_NIX_SHELL
    set_color blue
    if test "$name" = "nix-shell-env" -o "$name" = "shell"
      echo -n " [nix]"
    else
      echo -n " ["(string replace -r -- '-env$' "" $name)"]"
    end
    set_color normal
  end

  if test $last_status -eq 0
    echo -n ' > '
  else
    set_color red
    echo -n ' > '
    set_color normal
  end
end
