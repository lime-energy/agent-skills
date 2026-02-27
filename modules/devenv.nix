# devenv module for declarative agent skill management.
#
# Usage in a project's devenv.nix:
#
#   { inputs, ... }:
#   {
#     imports = [ inputs.agent-skills.devenvModules.default ];
#
#     agent-skills.enable = true;
#     agent-skills.targets.claude = true;
#   }

{ agentSkillsLib, selection, flakeSelf }:

{ config, lib, pkgs, ... }:

let
  cfg = config.agent-skills;

  # Merge extra project-local skills into the shared selection
  extraSourceEntries = lib.imap0 (i: path: {
    name = "extra-${toString i}";
    value = { inherit path; };
  }) cfg.extraSkills;

  extraSources = lib.listToAttrs extraSourceEntries;
  extraCatalog = agentSkillsLib.discoverCatalog extraSources;

  # Build the combined selection: shared manifest + project extras
  combinedSelection =
    let
      extraIds = builtins.attrNames extraCatalog;
      extraSelected = agentSkillsLib.selectSkills {
        catalog = extraCatalog;
        sources = extraSources;
        allowlist = extraIds;
      };
    in
    selection // extraSelected;

  bundle = agentSkillsLib.mkBundle {
    inherit pkgs;
    selection = combinedSelection;
  };

  # Target directory mapping
  targetDests = {
    claude   = ".claude/skills";
    copilot  = ".github/skills";
    codex    = ".codex/skills";
    cursor   = ".cursor/skills";
    windsurf = ".windsurf/skills";
    gemini   = ".gemini/skills";
  };

  enabledTargets = lib.filterAttrs (name: enabled: enabled) cfg.targets;

  syncCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _:
    let dest = targetDests.${name}; in
    ''
      mkdir -p "${dest}"
      ${pkgs.rsync}/bin/rsync -aL --delete --chmod=Du+w "${bundle}/" "${dest}/"
    ''
  ) enabledTargets);

in
{
  options.agent-skills = {
    enable = lib.mkEnableOption "Declarative agent skill management";

    targets = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = {};
      description = ''
        Which agent targets to install skills for. Keys are agent names
        (claude, copilot, codex, cursor, windsurf, gemini), values are booleans.
      '';
      example = { claude = true; copilot = true; };
    };

    extraSkills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        Additional skill directory paths from the project. Each path should
        contain <skill-name>/SKILL.md subdirectories.
      '';
      example = [ ./skills ];
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.rsync ];

    enterShell = lib.mkIf (enabledTargets != {}) syncCommands;
  };
}
