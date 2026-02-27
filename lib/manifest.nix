# Shared skill manifest — single source of truth for the organization.
#
# Each entry: { source, subdir, skills }
#   source: path to the skill source (flake input or local path)
#   subdir: directory within the source containing <skill-name>/SKILL.md dirs
#   skills: [ "*" ] for all skills, or list of specific skill names
#
# Add new entries here. They automatically appear in devenv projects
# that import the agent-skills module.

{ skillSources, localSkillsPath }:

[
  # ── Organization custom skills ──────────────────────────────────────
  { source = localSkillsPath;                     subdir = ".";                                  skills = [ "*" ]; }

  # ── External: wildcard (all skills from source) ─────────────────────
  { source = skillSources.dcramer-dex;             subdir = "plugins/dex/skills";                 skills = [ "*" ]; }
  { source = skillSources.microsoft;               subdir = ".github/plugins/deep-wiki/skills";   skills = [ "*" ]; }

  # ── External: cherry-picked skills ──────────────────────────────────
  { source = skillSources.anthropics;              subdir = "skills";       skills = [ "mcp-builder" "skill-creator" "pdf" ]; }
  { source = skillSources.vercel-labs;             subdir = "skills";       skills = [ "find-skills" ]; }
  { source = skillSources.sundial-openclaw;        subdir = "skills";       skills = [ "email-management-expert" ]; }
  { source = skillSources.softaworks;              subdir = "skills";       skills = [ "agent-md-refactor" "mermaid-diagrams" "marp-slide" ]; }
  { source = skillSources.github-copilot;          subdir = "skills";       skills = [ "gh-cli" "git-commit" "prd" "github-issues" "mcp-cli" "make-skill-template" ]; }
  { source = skillSources.steipete;                subdir = "skills";       skills = [ "1password" ]; }
  { source = skillSources.kepano-obsidian;         subdir = "skills";       skills = [ "obsidian-markdown" "obsidian-bases" "json-canvas" "defuddle" ]; }
  { source = skillSources.jackal-obsidian-cli;     subdir = "plugins/obsidian-cli/skills";        skills = [ "obsidian-cli" ]; }
]
