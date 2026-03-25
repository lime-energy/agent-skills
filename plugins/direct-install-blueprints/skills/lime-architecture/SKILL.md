---
name: lime-architecture
description: "Lime Energy platform architecture reference. Use when understanding system design, event flows, service integrations, multi-tenancy, authentication, or per-app differences across Auditor, Closer, and Prospector."
---

# Lime Energy Architecture

Reference skill for the Lime Energy direct-install platform architecture shared by Auditor, Closer, and Prospector.

## Reference Material

Read the full architecture document:

- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — Event flows, service map, multi-tenancy, auth, shared packages

## Event-Driven Data Flow

```
User edits form (React)
    → Apollo optimistic update (immediate UI)
    → GraphQL Mutation → AppSync API
    → VTL Resolver → DynamoDB (write)
    → DynamoDB Stream → Lambda (event handler)
        → AppSync Mutation (real-time push via subscription)
        → SDS / Kinesis (system-wide event propagation)
        → OpenSearch (search index, Prospector only)
```

## AWS Service Map

- **Frontend**: CloudFront CDN → S3 (static SPA), React 18 PWA + Cordova iOS
- **API**: AppSync GraphQL (Cognito + IAM dual auth), VTL resolvers + Lambda data sources
- **Compute**: Lambda Node.js 20.x (5-9 functions/app), DynamoDB Streams + Kinesis triggers
- **Data**: DynamoDB (PAY_PER_REQUEST, streams), OpenSearch (Prospector), Kinesis/SDS
- **Auth**: Cognito User Pool (shared), Identity Pool (per app), OAuth 2.0 code flow
- **External**: Configurator (shared config), Sertifi (Closer), Hubspot/Sakari (Closer), AWS Location (Prospector)

## Multi-Tenancy

All data scoped by `programId` and `energyCompanyId`. ApplicationsTable has GSIs on both. All frontend queries require programId. ConfiguratorClient loads tenant-specific settings.

## Authentication Flow

1. User lands → Amplify checks Cognito session
2. No session → Cognito Hosted UI (OAuth 2.0 code flow)
3. Tokens returned (ID, Access, Refresh)
4. ID token → AppSync (COGNITO_USER_POOLS auth)
5. Identity Pool → AWS credentials for IAM auth
6. Lambda → IAM roles for internal AppSync mutations

## Per-App Differences

| Feature | Auditor | Closer | Prospector |
|---------|---------|--------|------------|
| Domain | Energy audit field work | E-signature & closing | Geospatial search & leads |
| Unique | Scopes, Floors, Rooms, measure plugins, @dnd-kit | Sertifi e-sign, Hubspot, Sakari SMS, JEXL | OpenSearch, H3 hex grid, AWS Location, Context providers |
| Search | None | None | OpenSearch (full-text + geo) |

## Key Architectural Decisions

- **VTL over Lambda resolvers** for simple CRUD — lower latency (no cold start), lower cost
- **PAY_PER_REQUEST billing** on all DynamoDB tables — simplifies capacity management for variable workloads
- **RxJS in Lambda handlers** — enables reactive composition of stream processing pipelines
- **Fragment-based GraphQL** — Apollo normalized cache requires consistent fragment usage
- **Nested CloudFormation stacks** — keeps DynamoDB and Cognito resources isolated and reusable
