{
  description = "Declarative agent skill management for development projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Declarative skill discovery, bundling, and deployment
    agent-skills-nix.url = "github:Kyure-A/agent-skills-nix";

    # ── Skill source repos ──────────────────────────────────────────────
    # Each repo is pinned in flake.lock. flake = false since these are
    # just source trees containing SKILL.md files, not Nix flakes.

    skills-anthropics.url = "github:anthropics/skills";
    skills-anthropics.flake = false;
    skills-dcramer-dex.url = "github:dcramer/dex";
    skills-dcramer-dex.flake = false;
    skills-vercel-labs.url = "github:vercel-labs/skills";
    skills-vercel-labs.flake = false;
    skills-sundial-openclaw.url = "github:sundial-org/awesome-openclaw-skills";
    skills-sundial-openclaw.flake = false;
    skills-softaworks.url = "github:softaworks/agent-toolkit";
    skills-softaworks.flake = false;
    skills-github-copilot.url = "github:github/awesome-copilot";
    skills-github-copilot.flake = false;
    skills-steipete.url = "github:steipete/agent-scripts";
    skills-steipete.flake = false;
    skills-kepano-obsidian.url = "github:kepano/obsidian-skills";
    skills-kepano-obsidian.flake = false;
    skills-jackal-obsidian-cli.url = "github:jackal092927/obsidian-official-cli-skills";
    skills-jackal-obsidian-cli.flake = false;
    skills-microsoft.url = "github:microsoft/skills";
    skills-microsoft.flake = false;
  };

  outputs = { self, nixpkgs, agent-skills-nix, ... } @ inputs:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f nixpkgs.legacyPackages.${system}
      );

      # Skill source paths, resolved from flake inputs
      skillSources = {
        anthropics = inputs.skills-anthropics;
        dcramer-dex = inputs.skills-dcramer-dex;
        vercel-labs = inputs.skills-vercel-labs;
        sundial-openclaw = inputs.skills-sundial-openclaw;
        softaworks = inputs.skills-softaworks;
        github-copilot = inputs.skills-github-copilot;
        steipete = inputs.skills-steipete;
        kepano-obsidian = inputs.skills-kepano-obsidian;
        jackal-obsidian-cli = inputs.skills-jackal-obsidian-cli;
        microsoft = inputs.skills-microsoft;
      };

      # The shared skill manifest — single source of truth
      manifest = import ./lib/manifest.nix {
        inherit skillSources;
        localSkillsPath = "${self}/skills";
      };

      # Source/selection helpers
      sourcesLib = import ./lib/sources.nix { lib = nixpkgs.lib; };

      # agent-skills-nix library (path sources only, no input resolution needed)
      agentSkillsLib = import "${agent-skills-nix}/lib" {
        lib = nixpkgs.lib;
        inputs = {};
      };

      # Build catalog and selection from manifest
      allSources = sourcesLib.mkSources manifest;
      catalog = agentSkillsLib.discoverCatalog allSources;
      allowlist = agentSkillsLib.allowlistFor {
        inherit catalog;
        sources = allSources;
        enableAll = sourcesLib.mkEnableAll manifest;
        enable = sourcesLib.mkEnable manifest;
      };
      selection = agentSkillsLib.selectSkills {
        inherit catalog;
        sources = allSources;
        allowlist = allowlist;
      };
    in
    {
      # ── devenv module ───────────────────────────────────────────────────
      # Import in your project's devenv.nix:
      #   imports = [ inputs.agent-skills.devenvModules.default ];
      devenvModules.default = import ./modules/devenv.nix {
        inherit agentSkillsLib selection;
        flakeSelf = self;
      };

      # ── Pre-built bundles ───────────────────────────────────────────────
      packages = forAllSystems (pkgs: {
        bundle = agentSkillsLib.mkBundle { inherit pkgs selection; };
      });

      # ── Lib for advanced usage ──────────────────────────────────────────
      lib = {
        inherit manifest skillSources sourcesLib;
        inherit agentSkillsLib catalog allowlist selection;
      };
    };
}
