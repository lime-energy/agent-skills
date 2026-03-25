---
name: lime-scaffold-site
description: "Generate a complete Lime Energy application from scratch — monorepo structure, SAM template, nested stacks, GraphQL schema, React frontend, CI/CD workflows. Use when creating an entirely new direct-install site."
---

# Scaffold Complete Site

Generate a complete Lime Energy application with the standard monorepo structure matching Auditor, Closer, and Prospector.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — Platform overview, service map
- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — Full SAM template skeleton, nested stacks
- `${CLAUDE_PLUGIN_ROOT}/references/frontend-patterns.md` — React app structure, config
- `${CLAUDE_PLUGIN_ROOT}/references/lambda-patterns.md` — Handler patterns
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — All naming conventions

## Inputs

- **App name** (lowercase, e.g., `inspector`)

## Directory Structure Generated

```
<app-name>/
├── backend/
│   ├── <app-name>.yml              # Main SAM template (1,300+ lines)
│   ├── dynamodb-template.yml       # DynamoDB nested stack
│   ├── cognito-template.yml        # Cognito nested stack
│   ├── schema.graphql              # GraphQL schema
│   ├── resolvers/                  # VTL request/response pairs
│   │   ├── Query-getApplication.request
│   │   ├── Query-getApplication.response
│   │   ├── Mutation-updateApplication.request
│   │   └── ...
│   ├── src/
│   │   ├── dynamo-to-appsync/      # Stream handler
│   │   │   ├── index.ts
│   │   │   └── application-controller.ts
│   │   └── common/
│   │       ├── appsync.ts
│   │       ├── appsync-request-factory.ts
│   │       ├── models.ts
│   │       └── fragments.ts
│   ├── package.json
│   └── tsconfig.json
├── src/
│   ├── api/
│   │   ├── fragments.ts
│   │   ├── queries.ts
│   │   ├── mutations.ts
│   │   └── subscriptions.ts
│   ├── components/
│   │   ├── root/
│   │   └── common/
│   ├── data/
│   │   └── models.ts
│   ├── repository.ts
│   ├── index.tsx
│   └── App.tsx
├── public/
│   └── index.html
├── cordova/
│   └── config.xml
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── deploy.yml
│       ├── deploy-ios.yml
│       ├── lint-cfn.yml
│       ├── lint-code.yml
│       └── release-manager.yml
├── package.json
├── craco.config.js
├── tsconfig.json
└── .releaserc
```

## Key Resources in Main SAM Template

- `AWS::AppSync::GraphQLApi` — Cognito + IAM dual auth
- `AWS::AppSync::GraphQLSchema` — inline or file-based
- `AWS::CloudFormation::Stack` — DynamoDB nested stack
- `AWS::CloudFormation::Stack` — Cognito nested stack
- `AWS::S3::Bucket` — Frontend static hosting
- `AWS::CloudFront::Distribution` — CDN with OAI
- `AWS::Serverless::Function` — dynamo-to-appsync handler
- AppSync DataSources, Resolvers for base types

## Base Types Included

- `Application` — top-level entity with programId, energyCompanyId GSIs
- `Customer` — linked to Application

## Post-Scaffold Steps

1. Update `__VARIABLE__` placeholders in frontend config for the new app
2. Set up Cognito User Pool Client in the shared User Pool
3. Configure GitHub repository secrets for CI/CD
4. Run `npm install` in both root and `backend/`
5. Deploy with `sam deploy` to create the initial stack
