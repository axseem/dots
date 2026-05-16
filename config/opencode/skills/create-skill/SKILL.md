---
name: create-skill
description: Create opencode skills with correct structure, frontmatter, naming, and placement
---

Create opencode skills following these rules.

## Docs

<https://opencode.ai/docs/skills.md>

## Placement

`config/opencode/skills/<name>/SKILL.md` (nix-managed, symlinked to `~/.config/opencode/skills/<name>/SKILL.md`).

OpenCode also scans `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` walking up from cwd to git root. Global: `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`.

## Frontmatter

YAML frontmatter required:

- `name` — must match directory name
- `description` — max 1024 chars, specific enough for agent selection

Optional: `license`, `compatibility`, `metadata` (string map). Unknown fields ignored.

## Name rules

- Lowercase alphanumeric, single hyphens
- 1–64 chars
- No leading/trailing/consecutive hyphens
- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

## How agents discover and load skills

Skills appear in `skill` tool description as `<available_skills>` list (name + description). Agent calls `skill({ name: "skill-name" })` to load full content into context.

## Content structure

1. What skill does — terse directives
2. When to use — trigger conditions
3. Workflow steps — ordered, actionable
4. Constraints — what not to do

Trust precise names over explanations. Flat lists over nesting.

## Permissions

Pattern-based, configured in `opencode.json`:

- `allow` — loads immediately
- `deny` — hidden from agent
- `ask` — user approves before loading

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

### Per-agent override

Custom agents (frontmatter): `permission: { skill: { "pattern": "allow" } }`
Built-in agents (opencode.json): `agent: { "agent-name": { permission: { skill: { "pattern": "allow" } } } }`

### Disable skill tool entirely

Custom agents: `tools: { skill: false }`
Built-in agents: `agent: { "agent-name": { tools: { skill: false } } }`

Omits `<available_skills>` section entirely.

## Troubleshooting

- `SKILL.md` all caps
- Frontmatter has `name` + `description`
- Names unique across all locations
- Denied skills hidden from agents
