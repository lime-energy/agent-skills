---
name: lime-update-cfn-stack
description: "Safely modify CloudFormation/SAM templates with breaking change detection and cross-stack reference integrity. Use when editing the main SAM template, DynamoDB nested stack, or Cognito nested stack."
---

# Update CloudFormation Stack

Safely modify CloudFormation and SAM templates with validation, breaking change detection, and cross-stack reference integrity checks.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — Template structure, nested stacks
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — CloudFormation conventions

## Pre-Change Validation

Before applying any change, check for:

### Breaking Changes (BLOCK without confirmation)
- Changing a DynamoDB table's primary key → requires table replacement + data migration
- Removing a nested stack output that's referenced by the parent
- Changing a resource's logical ID → resource replacement
- Removing or renaming a parameter used by nested stacks

### Safe Changes (proceed)
- Adding new GSIs to existing tables
- Adding new resources
- Adding new outputs to nested stacks
- Adding new parameters
- Updating Lambda function code or environment variables

## Cross-Stack Reference Integrity

### Adding Outputs
When adding to `dynamodb-template.yml` or `cognito-template.yml`:
1. Add the Output in the nested stack
2. Reference via `!GetAtt DynamoDB.Outputs.<Name>` or `!GetAtt Cognito.Outputs.<Name>` in parent

### Removing Outputs
1. Find ALL parent stack references: `!GetAtt <StackName>.Outputs.<OutputName>`
2. Update or remove each reference
3. Only then remove the output

### Adding Parameters
1. Add parameter to the target template
2. If nested stack needs it, add to parent's stack resource `Parameters:` section
3. If it's a secret, use `NoEcho: true`

## Template Formatting Rules

- Preserve existing indentation (2 spaces for YAML)
- Preserve comment structure and section ordering
- New Lambda functions go with other Lambda functions
- New datasources go with other datasources
- New resolvers go with other resolvers (alphabetical by type/field)

## Post-Change Validation

After making changes:
1. Run `sam validate --template backend/<app>.yml`
2. Run `cfn-lint backend/<app>.yml backend/dynamodb-template.yml backend/cognito-template.yml`
3. Verify all `!GetAtt` and `!Ref` cross-references resolve
4. Check that no circular dependencies were introduced
