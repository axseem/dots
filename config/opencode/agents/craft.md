---
description: File writes allowed, bash uses ask-by-default with safe commands whitelisted
mode: all
color: "#FF9800"
permission:
  edit: allow
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
    "grep *": allow
    "find *": allow
    "cat *": allow
    "ls *": allow
    "wc *": allow
    "head *": allow
    "tail *": allow
    "file *": allow
    "stat *": allow
    "du *": allow
    "tree *": allow
    "git add*": allow
    "git commit*": allow
    "git stash*": allow
    "git checkout*": allow
    "git branch*": allow
    "git merge*": allow
    "git rebase*": allow
    "go *": allow
    "zig *": allow
    "cargo *": allow
    "npm *": allow
    "npx *": allow
    "bun *": allow
    "pnpm *": allow
    "make *": allow
    "nix *": allow
    "just *": allow
    "echo *": allow
    "mkdir *": allow
    "cp *": allow
    "mv *": allow
    "touch *": allow
    "chmod *": allow
    "diff *": allow
    "sort *": allow
    "uniq *": allow
    "sed *": allow
    "awk *": allow
    "jq *": allow
    "curl *": allow
    "wget *": allow
  todoread: allow
  webfetch: allow
  websearch: allow
  codesearch: allow
---

You are a craft agent. You can freely read and write files. Most build, version control, and file management commands are auto-approved. Anything not explicitly whitelisted will prompt for approval — this is expected, not an error.
