# Convert a skill manifest into agent-skills-nix sources and selections.
#
# Wildcard entries (skills = ["*"]) become a single source with enableAll.
# Cherry-picked entries become one source per skill, with subdir pointing
# directly at the skill directory. This avoids ID collisions between repos
# that share skill names (agent-skills-nix IDs are not source-namespaced).

{ lib }:

let
  isWildcard = entry: entry.skills == [ "*" ];

  # Wildcard sources: one source per entry, named "all-<index>"
  mkWildcardSources = manifest:
    lib.imap0 (i: entry: {
      name = "all-${toString i}";
      value = { path = entry.source; subdir = entry.subdir; };
    }) (builtins.filter isWildcard manifest);

  # Picked sources: one source per skill, subdir = "<base>/<skill>"
  # When SKILL.md is at the root of the scanned path (depth 0),
  # the source name becomes the skill ID.
  mkPickedSources = manifest:
    builtins.concatMap (entry:
      map (skill: {
        name = skill;
        value = { path = entry.source; subdir = "${entry.subdir}/${skill}"; };
      }) entry.skills
    ) (builtins.filter (e: !isWildcard e) manifest);

in
{
  # All sources (wildcard + picked), as an attrset for agent-skills-nix
  mkSources = manifest:
    lib.listToAttrs (mkWildcardSources manifest ++ mkPickedSources manifest);

  # Source names that should have all skills enabled
  mkEnableAll = manifest:
    map (s: s.name) (mkWildcardSources manifest);

  # Individual skill IDs to enable
  mkEnable = manifest:
    map (s: s.name) (mkPickedSources manifest);
}
