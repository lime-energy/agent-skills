---
name: lime-review-pr
description: "Domain-aware code review for Lime Energy PRs — cross-file consistency, convention compliance, subscription wiring, cache model completeness. Use when reviewing pull requests to Auditor, Closer, or Prospector."
---

# Review PR

Domain-aware code review that checks Lime Energy-specific patterns beyond what generic linters catch.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Naming and code conventions
- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — Event flow, subscription wiring
- `${CLAUDE_PLUGIN_ROOT}/references/vtl-templates.md` — VTL patterns
- `${CLAUDE_PLUGIN_ROOT}/references/frontend-patterns.md` — Cache model, repository pattern

## Review Checklist

### 1. Cross-File Consistency (Schema Changes)

If `backend/schema.graphql` is modified:
- [ ] New query/mutation fields have corresponding VTL resolver pairs in `backend/resolvers/`
- [ ] New types have corresponding frontend fragments in `src/api/fragments.ts`
- [ ] New queries have corresponding exports in `src/api/queries.ts`
- [ ] New mutations have corresponding exports in `src/api/mutations.ts`
- [ ] New subscriptions have corresponding exports in `src/api/subscriptions.ts`
- [ ] SAM template has `AWS::AppSync::Resolver` resources for new resolvers

### 2. DynamoDB Table Conventions

If `backend/dynamodb-template.yml` is modified:
- [ ] New tables use `BillingMode: PAY_PER_REQUEST`
- [ ] New tables enable `StreamSpecification: NEW_AND_OLD_IMAGES`
- [ ] GSIs use `Projection: ALL`
- [ ] Outputs added for TableName, TableArn, TableStreamArn
- [ ] DynamoDBRole policy includes new table ARN + index ARNs

### 3. Subscription Wiring

If real-time features are added:
- [ ] GraphQL subscription type defined in schema
- [ ] Stream mutation type (e.g., `update<Type>Stream`) defined
- [ ] Lambda handler sends mutation to AppSync via `sendToAppsync`
- [ ] Frontend subscribes via `src/api/subscriptions.ts`
- [ ] Subscription filtered by appropriate ID (applicationId, etc.)

### 4. Naming Convention Compliance

- [ ] GraphQL queries use `get<Type>` / `list<Types>` prefix
- [ ] GraphQL mutations use `update<Type>` / `put<Type>` / `delete<Type>` prefix
- [ ] GraphQL subscriptions use `on<Action><Type>` prefix
- [ ] Files use kebab-case (components, handlers, controllers)
- [ ] VTL files use `<Type>-<field>.request/response` pattern
- [ ] CloudFormation resources use PascalCase logical IDs

### 5. Cache Model Completeness

If new GraphQL types are added:
- [ ] Entry added to `src/data/models.ts`
- [ ] Fragment reference is correct
- [ ] Parent/child/sibling relationships defined
- [ ] `idName` matches the entity's primary key field
- [ ] `listName` matches the field name in the parent type

### 6. Frontend Patterns

- [ ] Fragments compose via template literal `${ChildFragment}`, not string concatenation
- [ ] Mutations use `callMutation` from repository with `cacheHandler`
- [ ] Optimistic responses include `__typename`
- [ ] No `useEffect` for data fetching (use Apollo `useQuery`)
- [ ] No server state stored in React `useState`

## Output

Organize findings by severity:
- **Must Fix** — broken cross-file references, missing resolvers, convention violations that will cause runtime errors
- **Should Fix** — convention deviations, missing subscriptions, incomplete cache models
- **Consider** — optimization opportunities, potential improvements
