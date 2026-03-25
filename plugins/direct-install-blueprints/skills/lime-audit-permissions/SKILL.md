---
name: lime-audit-permissions
description: "Audit IAM roles, Cognito configuration, and AppSync authorization for a Lime Energy app. Use for security reviews, permission tightening, or compliance checks."
---

# Audit Permissions

Map and audit IAM roles, Cognito settings, and AppSync authorization configuration for security and least-privilege compliance.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — IAM roles, Cognito patterns
- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — Auth flow, service map

## Audit Steps

### 1. Lambda Function → IAM Role Mapping

For each `AWS::Serverless::Function` in the SAM template:
- Extract the function name and its Policies/Role
- List all actions and resources granted
- Output a table: Function | Role | Actions | Resources

### 2. Over-Permission Detection

Flag:
- `Resource: "*"` — wildcard resource access
- `Action: "dynamodb:*"` — wildcard actions on a service
- Permissions for tables/resources not referenced in the function's code
- `Action: "*"` — full admin access

### 3. Least-Privilege Recommendations

For each flagged role, output a replacement policy with:
- Specific actions (e.g., `dynamodb:GetItem, dynamodb:Query` instead of `dynamodb:*`)
- Specific resource ARNs (table ARN + index ARN instead of `*`)
- Separate statements per resource group

### 4. Cognito Validation

Check the `cognito-template.yml`:
- Callback URLs use HTTPS (except `localhost` and app scheme deep links)
- Refresh token validity ≤ 30 days
- OAuth flows use authorization code (not implicit)
- Scopes are minimal

### 5. AppSync Authorization

Verify in the main SAM template:
- Default auth: `AMAZON_COGNITO_USER_POOLS`
- Additional auth: `AWS_IAM`
- No `API_KEY` auth mode in production
- Types have appropriate auth directives

### 6. Cross-Service Access

Map which services each Lambda can access:
- DynamoDB tables (via IAM)
- AppSync API (via IAM)
- S3 buckets (via IAM)
- Kinesis streams (via IAM)
- Other AWS services

## Output Format

```
## Permission Audit Report — <App Name>

### Summary
- X Lambda functions audited
- Y over-permissioned roles found
- Z recommendations generated

### Function: dynamo-to-appsync
Role: DynamoToAppsyncRole
| Action | Resource | Status |
|--------|----------|--------|
| dynamodb:GetRecords | InspectionsTable stream | OK |
| appsync:GraphQL | AppSync API /* | WARN: overly broad |

Recommendation: Restrict appsync:GraphQL to specific mutation ARNs
```
