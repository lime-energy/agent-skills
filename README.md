# agent-skills

Declarative agent skill management for development projects. Define your organization's shared skills once, install them everywhere with a single import.

Built on [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix) and designed for [devenv.sh](https://devenv.sh) projects.

## How It Works

```
┌─────────────────────────────────────────────────┐
│  agent-skills (this repo)                       │
│                                                 │
│  lib/manifest.nix    ← shared skill manifest    │
│  skills/             ← org custom skills        │
│  flake.lock          ← pinned source versions   │
│                                                 │
│  exports: devenvModules.default                  │
└───────────────────┬─────────────────────────────┘
                    │ import
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   project-a    project-b    project-c
   devenv.nix   devenv.nix   devenv.nix
```

All skill sources are pinned in `flake.lock`. When you run `nix flake update agent-skills` in a project, every project gets the same skill versions. No runtime downloads, no floating versions, fully reproducible.

## Quick Start

### 1. Add the input to your project's `flake.nix`

```nix
{
  inputs = {
    # ... your existing inputs ...
    agent-skills.url = "github:lime-energy/agent-skills";
  };

  # If using devenv.lib.mkFlake, inputs are passed through automatically
}
```

### 2. Import the module in your `devenv.nix`

```nix
{ inputs, pkgs, ... }:

{
  imports = [ inputs.agent-skills.devenvModules.default ];

  agent-skills = {
    enable = true;
    targets = {
      claude = true;    # → .claude/skills/
      copilot = true;   # → .github/skills/
    };
  };
}
```

### 3. Enter the shell

```bash
devenv shell
# Skills are synced to .claude/skills/ and .github/skills/
```

### 4. Add target directories to `.gitignore`

```gitignore
.claude/skills/
.github/skills/
.codex/skills/
.cursor/skills/
```

## Configuration

### Targets

Choose which agents receive skills in each project:

```nix
agent-skills.targets = {
  claude   = true;   # .claude/skills/
  copilot  = true;   # .github/skills/
  codex    = true;   # .codex/skills/
  cursor   = true;   # .cursor/skills/
  windsurf = true;   # .windsurf/skills/
  gemini   = true;   # .gemini/skills/
};
```

### Project-Local Skills

Add skills specific to a project alongside the shared ones:

```nix
agent-skills = {
  enable = true;
  targets.claude = true;

  # Directory containing <skill-name>/SKILL.md subdirectories
  extraSkills = [ ./skills ];
};
```

Project-local skills are merged with the shared manifest. If a project skill has the same ID as a shared skill, the project skill takes precedence.

### Example: Project with custom skills

```
my-project/
├── devenv.nix
├── flake.nix
├── skills/
│   └── my-api-guide/
│       └── SKILL.md       ← project-specific skill
└── src/
```

```nix
# devenv.nix
{ inputs, ... }:
{
  imports = [ inputs.agent-skills.devenvModules.default ];

  agent-skills = {
    enable = true;
    targets.claude = true;
    extraSkills = [ ./skills ];
  };
}
```

## Managing the Shared Manifest

The shared skill manifest lives in `lib/manifest.nix`. Each entry specifies a source, subdirectory, and which skills to include.

### Adding an external skill source

1. Add the flake input in `flake.nix`:

```nix
inputs = {
  # ...
  skills-my-source.url = "github:owner/repo";
  skills-my-source.flake = false;
};
```

2. Add it to `skillSources` in `flake.nix`:

```nix
skillSources = {
  # ...
  my-source = inputs.skills-my-source;
};
```

3. Add the entry in `lib/manifest.nix`:

```nix
# All skills from the source
{ source = skillSources.my-source; subdir = "skills"; skills = [ "*" ]; }

# Or cherry-pick specific skills
{ source = skillSources.my-source; subdir = "skills"; skills = [ "skill-a" "skill-b" ]; }
```

4. Run `nix flake lock` to pin the new input.

### Adding a custom organization skill

Create a directory under `skills/` with a `SKILL.md` file:

```
skills/
└── my-org-skill/
    ├── SKILL.md
    ├── scripts/        # optional
    ├── references/     # optional
    └── assets/         # optional
```

The skill is automatically included via the `localSkillsPath` wildcard source.

### How cherry-picking avoids ID collisions

Skill IDs in `agent-skills-nix` are **not namespaced by source**. If two repos both contain a `webapp-testing` skill, they collide. The manifest handles this by pointing `subdir` directly at each cherry-picked skill's directory:

```
# Instead of scanning all of skills/ and filtering:
{ source = src; subdir = "skills"; skills = [ "pdf" ]; }

# The source helper points subdir at skills/pdf/ directly.
# SKILL.md is found at depth 0, and the source name (= skill name)
# becomes the ID. No scanning of siblings, no collisions.
```

This is handled automatically by `lib/sources.nix`.

## Architecture

### File structure

```
├── flake.nix              # Inputs (skill sources) and outputs (devenv module, packages)
├── flake.lock             # Pinned versions of all skill sources
├── lib/
│   ├── manifest.nix       # Skill manifest: what to install
│   └── sources.nix        # Converts manifest → agent-skills-nix format
├── modules/
│   └── devenv.nix         # devenv module for project integration
└── skills/                # Organization custom skills
```

### Data flow

```
manifest.nix
    │
    ▼
sources.nix (mkSources, mkEnableAll, mkEnable)
    │
    ▼
agent-skills-nix lib (discoverCatalog → allowlistFor → selectSkills)
    │
    ▼
mkBundle (Nix store derivation with symlinked skills)
    │
    ▼
devenv module (rsync bundle → project target directories on shell entry)
```

### Updating skill versions

```bash
# Update all skill sources
nix flake update

# Update a specific source
nix flake update skills-anthropics

# Then in each project that consumes this:
nix flake update agent-skills
```

## Included Skills

### Wildcard sources (all skills)

| Source | Skills |
|--------|--------|
| `skills/` (this repo) | Organization custom skills |
| [dcramer/dex](https://github.com/dcramer/dex) | dex, dex-plan |
| [microsoft/skills](https://github.com/microsoft/skills) (deep-wiki) | wiki-architect, wiki-page-writer, wiki-changelog, wiki-researcher, wiki-qa, wiki-vitepress, wiki-onboarding, wiki-agents-md, wiki-llms-txt, wiki-ado-convert |

### Cherry-picked skills

| Source | Skills |
|--------|--------|
| [anthropics/skills](https://github.com/anthropics/skills) | mcp-builder, skill-creator, pdf |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | find-skills |
| [sundial-org/awesome-openclaw-skills](https://github.com/sundial-org/awesome-openclaw-skills) | email-management-expert |
| [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | agent-md-refactor, mermaid-diagrams, marp-slide |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | gh-cli, git-commit, prd, github-issues, mcp-cli, make-skill-template |
| [steipete/agent-scripts](https://github.com/steipete/agent-scripts) | 1password |
| [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | obsidian-markdown, obsidian-bases, json-canvas, defuddle |
| [jackal092927/obsidian-official-cli-skills](https://github.com/jackal092927/obsidian-official-cli-skills) | obsidian-cli |

## License

MIT
