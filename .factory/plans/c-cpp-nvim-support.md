# C/C++ Neovim Support — Implementation Plan

## Current State

**Already in place (no action needed):**
- `clang-tools` package installed system-wide via `modules/nixos/system/dev-tools.nix` → provides the `clangd` binary and `clang-format`
- Treesitter `c` and `cpp` parsers installed in nvim flake's `startupPlugins` (nix-managed)
- `vim.lsp.inlay_hint` toggle already mapped to `<leader>uh` in `keymaps.lua`
- Neovim uses the new `vim.lsp.config()` + `vim.lsp.enable()` API (0.11+)
- Plugin management: nixCats-nvim wraps lazy.nvim; nix manages core plugins, lazy.nvim handles lazy-loading specs

**What's missing:**
- No `clangd` LSP config file
- No `clangd_extensions.nvim` plugin (AST, type hierarchy, switch source/header, memory usage)
- No C/C++ formatter entry in conform.nvim
- No keymaps for clangd-specific commands

---

## Changes

All changes are in the **nvim repo** (`github:axseem/nvim`). No changes needed in the dots repo.

### 1. Create `lua/config/lsp/config/clangd.lua`

New file. Follows the same pattern as `zls.lua`, `nixd.lua`, etc. using `vim.lsp.config()`.

```lua
vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp" },
  root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git" },
})
```

**Rationale:**
- Config name `"clangd"` must match what `clangd_extensions.nvim` looks up via `vim.lsp.get_clients({ name = "clangd" })`.
- `root_markers` covers all standard project layouts: CMake (compile_commands.json), Makefile/bear (compile_commands.json), standalone flags (compile_flags.txt), `.clangd` config files, and git repos as fallback.
- No `offset_encoding` override needed — Neovim 0.11+ handles this correctly by default with clangd.

### 2. Update `lua/config/lsp/init.lua`

Add two lines following the existing pattern:

```lua
-- After the existing require() block:
require("config.lsp.config.clangd")

-- After the existing vim.lsp.enable() block:
vim.lsp.enable("clangd")
```

Insert alphabetically or at the end — consistency with the existing ordering (which is: marksman, nixd, lua_ls, basedpyright, rust_analyzer, ts_ls, svelte, eslint, zls). Place it after `basedpyright` and before `rust_analyzer` for alphabetical order, or at the end. Either works.

### 3. Create `lua/config/plugins/clangd-extensions.lua`

New file. Returns a lazy.nvim plugin spec, lazy-loaded on C/C++ filetypes.

```lua
return {
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    opts = {
      extensions = {
        inlay_hints = {
          inline = false, -- use Neovim's native inlay hints instead
        },
        ast = {
          -- defaults are fine
        },
        memory_usage = {
          border = "rounded",
        },
        symbol_info = {
          border = "rounded",
        },
      },
    },
    keys = {
      { "<leader>cA", "<cmd>ClangdAST<cr>", desc = "Clangd AST", ft = { "c", "cpp" } },
      { "<leader>cH", "<cmd>ClangdTypeHierarchy<cr>", desc = "Clangd Type Hierarchy", ft = { "c", "cpp" } },
      { "<leader>cM", "<cmd>ClangdMemoryUsage<cr>", desc = "Clangd Memory Usage", ft = { "c", "cpp" } },
      { "<leader>cS", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header", ft = { "c", "cpp" } },
    },
  },
}
```

**Rationale:**
- `ft = { "c", "cpp" }` — only loads when editing C/C++ files, zero overhead otherwise.
- `inlay_hints.inline = false` — Neovim 0.10+ has native `vim.lsp.inlay_hint`; no need for the plugin's custom implementation.
- Keymaps use the `<leader>c` namespace (consistent with existing `<leader>ca`, `<leader>cr`, `<leader>cc` code maps).
  - `<leader>cA` — AST view (capital A for distinction from `<leader>ca` = Code Action)
  - `<leader>cH` — Type Hierarchy (H for Hierarchy; distinct from `<leader>cH` hover which doesn't exist — hover is `K`)
  - `<leader>cM` — Memory usage
  - `<leader>cS` — Switch source/header (S for Switch)
- The `ft` on keymaps ensures they only bind in C/C++ buffers, avoiding conflicts.

### 4. Update `lua/config/plugins/init.lua`

Add the import in the lazy.nvim setup spec list (alongside existing imports):

```lua
{ import = "config.plugins.clangd-extensions" },
```

Place it after the `scheme` import or grouped with language-specific plugins.

### 5. Update `lua/config/plugins/conform.lua`

Add C/C++ formatter entries to `formatters_by_ft`:

```lua
formatters_by_ft = {
  -- ... existing entries ...
  c = { "clang-format" },
  cpp = { "clang-format" },
},
```

`clang-format` is provided by the `clang-tools` package already installed system-wide.

---

## No Changes Needed in Dots Repo

| Item | Status |
|------|--------|
| `clang-tools` (clangd binary) | Already in `modules/nixos/system/dev-tools.nix` |
| `clang-tools` (clang-format) | Same package, already installed |
| Treesitter `c` parser | Already in nvim flake's `startupPlugins` |
| Treesitter `cpp` parser | Already in nvim flake's `startupPlugins` |

**Note:** If the user wants clangd available on macOS too (the `macbook` darwin config), they would need to add `clang-tools` to the darwin system packages or home packages. Currently `dev-tools.nix` is only imported in the NixOS configuration.

---

## What This Gives You (rust-analyzer parity)

| Feature | rust-analyzer | clangd (after this plan) |
|---------|---------------|--------------------------|
| Code completion | ✅ | ✅ |
| Diagnostics | ✅ | ✅ |
| Go-to-definition | ✅ | ✅ |
| Find references | ✅ | ✅ |
| Rename | ✅ | ✅ |
| Code actions | ✅ | ✅ |
| Inlay hints | ✅ (native) | ✅ (native via `vim.lsp.inlay_hint`) |
| Hover documentation | ✅ | ✅ |
| Signature help | ✅ | ✅ |
| Type hierarchy | ✅ (via rust-analyzer extensions) | ✅ (`:ClangdTypeHierarchy`, `<leader>cH`) |
| AST inspection | ✅ (via rust-analyzer) | ✅ (`:ClangdAST`, `<leader>cA`) |
| Memory usage | N/A | ✅ (`:ClangdMemoryUsage`, `<leader>cM`) |
| Switch source/header | N/A | ✅ (`:ClangdSwitchSourceHeader`, `<leader>cS`) |
| Semantic highlighting | ✅ | ✅ |
| Call hierarchy | ✅ | ✅ |
| Formatting on save | ✅ (rustfmt) | ✅ (clang-format) |

---

## Project Setup Requirement: `compile_commands.json`

clangd requires compilation flags to function. Without them, you get no completions, diagnostics, or navigation. The standard approach:

**CMake projects:**
```bash
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ...
```

**Other build systems (Make, Meson, etc.):**
Use [Bear](https://github.com/rizsotto/Bear):
```bash
bear -- make
```

**Standalone/single files:**
Create a `.clangd` YAML file in the project root:
```yaml
CompileFlags:
  Add: [-std=c23, -Wall]
```

This is not part of the nvim config — it's per-project setup. But it's worth knowing since clangd is effectively non-functional without it.

---

## Optional: DAP Debugging (Not Included)

If C/C++ debugging is desired later, add `codelldb` (via mason or nix) and configure `nvim-dap`. This is a separate concern and adds significant complexity. Recommended as a follow-up task.

---

## Files Changed Summary

| File | Action | Repo |
|------|--------|------|
| `lua/config/lsp/config/clangd.lua` | **Create** | nvim |
| `lua/config/lsp/init.lua` | **Edit** (+2 lines) | nvim |
| `lua/config/plugins/clangd-extensions.lua` | **Create** | nvim |
| `lua/config/plugins/init.lua` | **Edit** (+1 line) | nvim |
| `lua/config/plugins/conform.lua` | **Edit** (+2 lines) | nvim |
