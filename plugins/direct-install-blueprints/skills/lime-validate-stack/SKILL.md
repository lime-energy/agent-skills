---
name: lime-validate-stack
description: "Validate CloudFormation templates, resolver-schema consistency, IAM completeness, and cross-stack references. Use before deploying or as a pre-PR check."
---

# Validate Stack

Comprehensive validation of a Lime Energy application's infrastructure: CloudFormation templates, GraphQL schema, resolvers, and IAM permissions.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — Expected template structure
- `${CLAUDE_PLUGIN_ROOT}/references/vtl-templates.md` — Expected resolver patterns
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Naming rules

## Validation Checks

### 1. CloudFormation Lint

```bash
# Lint all templates
cfn-lint backend/<app>.yml
cfn-lint backend/dynamodb-template.yml
cfn-lint backend/cognito-template.yml

# SAM validate
sam validate --template backend/<app>.yml
```

### 2. Resolver-Schema Consistency

For every file in `backend/resolvers/`:
- Parse the type and field name from the filename (e.g., `Query-getInspection.request`)
- Verify `backend/schema.graphql` has a matching field on the matching type
- Report orphaned resolvers (resolver exists, no schema field)

For every Query/Mutation/Subscription field in `schema.graphql`:
- Check that a resolver pair exists in `backend/resolvers/`
- Report missing resolvers (schema field exists, no resolver)

### 3. IAM Role Completeness

For each Lambda function:
- Parse the function's code to find DynamoDB table references, AppSync calls, S3 access, etc.
- Compare against the function's IAM policy in the SAM template
- Flag missing permissions
- Flag overly broad permissions (wildcards)

### 4. Cross-Stack Reference Integrity

Check all `!GetAtt <Stack>.Outputs.<Name>` references:
- Verify the referenced stack exists
- Verify the referenced output exists in the nested stack template
- Report broken references

Check all `!Ref` parameter references:
- Verify referenced parameters are defined
- Verify parameter types match usage

### 5. GraphQL Schema Validation

- Check for syntax errors
- Check for duplicate type definitions
- Verify all type references resolve (no undefined types)
- Verify auth directives present on types (`@aws_cognito_user_pools @aws_iam`)

### 6. Convention Compliance

- DynamoDB tables: PAY_PER_REQUEST billing, NEW_AND_OLD_IMAGES streams
- GSIs: ALL projection
- Resolver filenames: match `<Type>-<field>.request/response` pattern
- GraphQL naming: get/list/update/put/delete prefixes

## Output

Report organized by severity:
- **Errors** — must fix before deploy (broken references, missing permissions, syntax errors)
- **Warnings** — should fix (convention violations, overly broad permissions)
- **Info** — suggestions (unused outputs, potential optimizations)
