## Context

The Lime Energy platform runs three production applications (Auditor, Closer, Prospector) on a consistent AWS serverless stack: React 18 + AppSync + DynamoDB + Lambda, managed via SAM/CloudFormation with nested stacks. The wes_marketplace repo is an agent marketplace containing Claude Code plugins, standalone skills (Nix-distributed), and shared reference material.

The "Direct Install Blueprints" plugin (`plugins/direct-install-blueprints/`) is a Claude Code plugin that bundles skills, agents, MCP servers, and reference docs for the Lime Energy platform. It includes three architect agents (cloud, frontend, native-app), AWS MCP servers (CFN, AppSync, DynamoDB, Lambda, CloudWatch), TypeScript LSP, and shared reference documents extracted from the three production repos.

The three repos are private GitHub repos under the `lime-energy` org. All follow identical patterns: `backend/<app>.yml` (main SAM template), `backend/dynamodb-template.yml`, `backend/cognito-template.yml`, `backend/schema.graphql`, `backend/resolvers/` (VTL), `backend/src/` (Lambda handlers in TypeScript), `src/` (React frontend), `.github/workflows/` (CI/CD).

## Goals / Non-Goals

**Goals:**
- Encode the Lime Energy platform patterns as reusable agent skills that work across all three repos
- Skills are SKILL.md files with optional `references/`, `scripts/`, and `assets/` subdirectories
- Each skill is self-contained — installable and usable independently
- Group all 15 skills under a `skills/` subdirectory structure in this repo
- Skills can reference each other but don't require each other
- Cover the full lifecycle: creating new sites, extending existing sites, operating in production

**Non-Goals:**
- Not building custom CLI tools or binaries — skills are prompt-based with optional shell scripts
- Not modifying the Nix flake infrastructure (the wildcard already picks up local skills)
- Not creating a separate plugin package format — skills follow the standard SKILL.md convention
- Not implementing the actual code changes that skills would generate — skills are instructions, not generators
- Not covering non-Lime-Energy projects — these skills are specific to the Lime platform patterns

## Decisions

### Decision 1: Claude Code plugin structure

**Choice:** Package as a Claude Code plugin at `plugins/direct-install-blueprints/` with agents, skills, MCP servers, LSP, and shared references — not flat skills in the repo root.

**Rationale:** A plugin provides a richer delivery mechanism than standalone skills: agents can orchestrate across skills, MCP servers provide live AWS access, LSP gives type checking, and everything installs as a single unit. The Nix flake system remains for distributing standalone skills to non-Claude-Code environments.

**Alternative considered:** Flat skills directory. This was the original design but doesn't support agents, MCP servers, or LSP integration.

### Decision 2: Prefix all skill names with `lime-`

**Choice:** All skills use `lime-` prefix (e.g., `lime-scaffold-site`, `lime-add-dynamo-table`).

**Rationale:** Prevents name collisions with external skills (e.g., a generic `scaffold-site` from another source). Makes it clear these are Lime-platform-specific. Enables easy filtering/discovery.

**Alternative considered:** No prefix, relying on context. Rejected because the manifest pulls skills from 7+ external sources and name collisions are likely.

### Decision 3: Reference documents as plugin-level shared assets

**Choice:** Place shared reference documents in `plugins/direct-install-blueprints/references/` — a plugin-level directory that agents and skills reference via `${CLAUDE_PLUGIN_ROOT}/references/`. Not a skill, not underscore-prefixed.

**Rationale:** Reference docs (architecture, conventions, CloudFormation patterns, VTL templates, Lambda patterns, frontend patterns) are knowledge that agents and skills consume — they are not skills themselves. Placing them at the plugin root makes them accessible to all components via the standard plugin path variable.

**Alternative considered:** `_lime-references/` as a pseudo-skill directory. Rejected because the underscore prefix was a hack to avoid Nix discovery, and reference docs aren't skills.

### Decision 4: Shell scripts for repeatable operations

**Choice:** Operations skills (deploy-site, diagnose-lambda, validate-stack) include shell scripts in their `scripts/` directory that wrap AWS CLI / SAM CLI commands.

**Rationale:** These operations involve multi-step CLI workflows that benefit from automation. The SKILL.md provides the instructions and context; the scripts provide the execution.

**Alternative considered:** Pure prompt-based instructions with no scripts. Rejected because deployment and diagnostic workflows are error-prone when typed manually each time.

### Decision 5: Template files for scaffolding skills

**Choice:** Scaffolding skills (scaffold-site, scaffold-lambda, scaffold-resolver, etc.) include template files in their `references/` directory — actual CloudFormation snippets, VTL template pairs, TypeScript handler skeletons, and React component templates.

**Rationale:** The patterns are precise and must match exactly. Providing real template files ensures the agent generates correct code that matches the established conventions rather than approximating them.

**Alternative considered:** Describe patterns in prose only. Rejected because VTL syntax, CloudFormation resource definitions, and TypeScript patterns are too precise for prose descriptions — real templates eliminate ambiguity.

### Decision 6: Build order — reference skills first, then scaffolding, then operations

**Choice:** Implement in this order: (1) lime-conventions + lime-architecture, (2) scaffold-resolver + add-graphql-type + add-dynamo-table, (3) scaffold-lambda + scaffold-frontend + add-lambda-trigger, (4) scaffold-site + update-cfn-stack, (5) operations skills.

**Rationale:** Reference skills inform all others and are immediately useful. The highest-frequency development tasks (adding types, resolvers, tables) come next. Full-site scaffolding is less frequent. Operations skills have the most external dependencies (AWS access, CloudWatch, etc.) and should be last.

## Risks / Trade-offs

- **[Risk] Skills become stale as repos evolve** → Mitigation: Reference skills link to actual repo files where possible. Include a "last verified" date in each SKILL.md. The review-pr skill can flag when patterns diverge.

- **[Risk] Template files may not cover all variations** → Mitigation: Templates cover the 80% case. Skills include guidance for common variations (e.g., "if your table needs a sort key, add..."). The agent can adapt.

- **[Risk] Private repo access required for skills to work** → Mitigation: Skills include the patterns inline in references/ rather than requiring repo cloning at runtime. The knowledge is baked into the skill.

- **[Risk] @lime-energy/* packages update and break patterns** → Mitigation: Pin package versions in template files. Include a note in lime-conventions about checking package changelogs.

- **[Trade-off] 15 skills is a large surface area** → Accepted. Each skill is independent and can be built incrementally. The phased build order (Decision 6) ensures value is delivered early.

- **[Trade-off] Shared references create a coupling point** → Accepted. The alternative (duplication) is worse. References are read-only assets that change infrequently.
