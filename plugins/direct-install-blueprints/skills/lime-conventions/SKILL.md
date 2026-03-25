---
name: lime-conventions
description: "Lime Energy naming patterns, code organization, and conventions reference. Use when naming new GraphQL types, files, CloudFormation resources, or when checking if code follows established patterns across Auditor, Closer, and Prospector."
---

# Lime Energy Conventions

Reference skill for naming patterns and code organization conventions used across all Lime Energy direct-install applications.

## Reference Material

Read the full conventions document for authoritative patterns:

- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Complete naming rules, file structure, code patterns
- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — System context for why these conventions exist

## Quick Reference

### GraphQL Naming

| Category | Convention | Examples |
|----------|-----------|----------|
| Types | PascalCase | `Application`, `ConditionInstance` |
| Input Types | `<Type>Input` | `ApplicationInput` |
| Queries | `get<Type>`, `list<Types>` | `getApplication`, `listApplications` |
| Mutations | `update<Type>`, `put<Type>`, `delete<Type>` | `updateApplication`, `putRoom` |
| Subscriptions | `on<Action><Type>` | `onUpdateApplication`, `onPutRoom` |
| Fragments | `<Type>` or `<Type>Fragment` | `Application`, `ConditionInstanceFragment` |

### File Naming

| Location | Convention | Examples |
|----------|-----------|----------|
| Backend handlers | kebab-case directories | `dynamo-to-appsync/`, `sds-to-appsync/` |
| Backend controllers | kebab-case | `application-controller.ts` |
| VTL resolvers | `<Type>-<field>.request/response` | `Query-getApplication.request` |
| Frontend API files | nouns | `queries.ts`, `mutations.ts`, `fragments.ts` |
| Frontend components | kebab-case `.tsx` | `inspection-detail.tsx` |
| CloudFormation | kebab-case `.yml` | `auditor.yml`, `dynamodb-template.yml` |

### CloudFormation Conventions

- Main template: `backend/<app-name>.yml`
- Transform: `AWS::Serverless-2016-10-31`
- Nested stacks: `dynamodb-template.yml`, `cognito-template.yml`
- Parameters: PascalCase (`ApiName`, `AppStage`, `StackEnv`)
- Resources: PascalCase by purpose (`ApplicationsTable`, `DynamoDBRole`)
- All DynamoDB tables: PAY_PER_REQUEST, streams NEW_AND_OLD_IMAGES

### Frontend Organization

- API files in `src/api/` — fragments.ts, queries.ts, mutations.ts, subscriptions.ts
- Components in `src/components/root/` (feature) and `src/components/common/` (shared)
- Cache models in `src/data/models.ts` — CacheHandler from @lime-energy/react-pwa
- Repository in `src/repository.ts` — callMutation wrappers with optimistic updates
- Fragments compose via template literal interpolation: `${ChildFragment}`

### Backend Organization

- Handlers in `backend/src/<function>/index.ts`
- Controllers per entity in same directory
- Common library in `backend/src/common/` — appsync.ts, models.ts, fragments.ts
- RxJS pipelines for async stream processing
- @lime-energy/lambda-routers for event type routing
