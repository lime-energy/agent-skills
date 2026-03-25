# wes_marketplace

Agent marketplace for Wes — Claude Code plugins, skills, and agents for development projects.

## Structure

```
wes_marketplace/
├── plugins/                          # Claude Code plugins
│   └── direct-install-blueprints/    # Lime Energy direct-install platform
│       ├── .claude-plugin/plugin.json
│       ├── agents/                   # Cloud, Frontend, Native architects
│       ├── skills/                   # Platform-specific skills
│       ├── references/               # Shared architecture & pattern docs
│       ├── commands/                 # Slash commands
│       ├── .mcp.json                 # AWS MCP servers (CFN, AppSync, DDB, Lambda, CloudWatch)
│       └── .lsp.json                 # TypeScript LSP
├── flake.nix                         # Nix flake for skill distribution
├── lib/                              # Nix skill manifest & source helpers
├── modules/                          # devenv module for project integration
├── skills/                           # Standalone skills (Nix-distributed)
└── openspec/                         # Change management
```

## Plugins

### direct-install-blueprints

Blueprints, agents, and tools for the Lime Energy direct-install platform (Auditor, Closer, Prospector).

**Agents:**
- `cloud-architect` — SAM/CloudFormation, DynamoDB, AppSync, Lambda, event architecture
- `frontend-architect` — React 18, Apollo/AppSync client, MUI, cache models, repository pattern
- `native-app-architect` — Cordova, iOS builds, offline-first, mobile auth

**MCP Servers (AWS Labs):**
- CloudFormation (`awslabs.cfn-mcp-server`)
- SAM/Serverless (`awslabs.aws-serverless-mcp-server`)
- AppSync (`awslabs.aws-appsync-mcp-server`)
- DynamoDB (`awslabs.dynamodb-mcp-server`)
- Lambda (`awslabs.lambda-tool-mcp-server`)
- CloudWatch (`awslabs.cloudwatch-mcp-server`)

**LSP:** TypeScript language server

**Install:**

Add the marketplace, then install the plugin:

```shell
# Add the marketplace (once)
/plugin marketplace add lime-energy/wes_marketplace

# Install the plugin
/plugin install direct-install-blueprints@wes-marketplace
```

For local development (from a clone of this repo):

```shell
/plugin marketplace add ./path/to/wes_marketplace
/plugin install direct-install-blueprints@wes-marketplace
```

**Prerequisites:** AWS MCP servers require `uv` ([install](https://docs.astral.sh/uv/getting-started/installation/)) and a configured `AWS_PROFILE`. TypeScript LSP requires `typescript-language-server` (`npm i -g typescript-language-server typescript`).

## Skill Distribution (Nix)

The Nix flake system distributes standalone skills to projects via devenv. This is separate from the plugin system.

### Quick Start

```nix
# flake.nix
{
  inputs.wes-marketplace.url = "github:lime-energy/wes_marketplace";
}
```

```nix
# devenv.nix
{
  imports = [ inputs.wes-marketplace.devenvModules.default ];
  agent-skills = {
    enable = true;
    targets.claude = true;
  };
}
```

### Included Skills

| Source | Skills |
|--------|--------|
| [dcramer/dex](https://github.com/dcramer/dex) | dex, dex-plan |
| [microsoft/skills](https://github.com/microsoft/skills) | wiki-architect, wiki-page-writer, wiki-changelog, wiki-researcher, wiki-qa, wiki-vitepress, wiki-onboarding, wiki-agents-md, wiki-llms-txt, wiki-ado-convert |
| [anthropics/skills](https://github.com/anthropics/skills) | mcp-builder, skill-creator, pdf |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | find-skills |
| [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | agent-md-refactor, mermaid-diagrams, marp-slide |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | gh-cli, git-commit, prd, github-issues, mcp-cli, make-skill-template |
| [steipete/agent-scripts](https://github.com/steipete/agent-scripts) | 1password |

## License

MIT
