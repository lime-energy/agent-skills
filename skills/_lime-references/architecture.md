# Lime Energy Platform Architecture Reference

Last verified: 2026-03-04

## Platform Overview

Three production applications sharing 95% identical architecture:

| App | Domain | Unique Features |
|-----|--------|----------------|
| **Auditor** | Energy audit field work | Scopes, Floors, Rooms, ConditionInstances, ControlPoints; @dnd-kit reordering; JuicerServiceEngine; measure plugins |
| **Closer** | E-signature & closing | Audits, ESignFiles, Facilities; Sertifi (e-sign), Hubspot (email/CRM), Sakari (SMS); JEXL financing decoder |
| **Prospector** | Geospatial search & leads | OpenSearch (full-text + geo); H3 hex grid aggregation; AWS Location Service geocoding; extensive React Context providers |

## Event-Driven Data Flow

```
User edits form (React component)
    |
    v
Apollo Client optimistic update   <--- immediate UI feedback
    |
    v
GraphQL Mutation --> AppSync API
    |
    v
VTL Resolver --> DynamoDB (write)
    |
    v
DynamoDB Stream --> Lambda (event handler)
    |
    +----> AppSync Mutation (real-time push to other clients via subscription)
    +----> SDS / Kinesis (system-wide event propagation)
    +----> OpenSearch (search index update, Prospector only)
```

### Stream Processing Paths

```
DynamoDB Stream Triggers:
  dynamo-to-appsync  --> LambdaAppSyncClient.postMutation()  --> Real-time UI updates
  dynamo-to-sds      --> Protobuf serialization               --> Kinesis SDS stream
  dynamo-to-opensearch --> OpenSearch bulk index               --> Search index (Prospector)

Kinesis/SDS Triggers:
  sds-to-appsync     --> Decodes Protobuf events              --> AppSync mutations
  sds-to-opensearch  --> Decodes events                       --> OpenSearch index
```

## AWS Service Map

```
Frontend Layer:
  CloudFront CDN --> S3 Bucket (static website, SPA routing via custom error pages)
  React 18 PWA + Cordova iOS wrapper

API Layer:
  AWS AppSync GraphQL API
    Auth: AMAZON_COGNITO_USER_POOLS (primary) + AWS_IAM (secondary)
    Data Sources: DynamoDB tables (direct VTL) + Lambda functions
    Schema: backend/schema.graphql (600-750 lines per app)
    Resolvers: backend/resolvers/ (VTL request/response pairs)

Compute Layer:
  AWS Lambda (Node.js 20.x, TypeScript)
    5-9 functions per app
    Event sources: DynamoDB Streams, Kinesis, S3, AppSync
    Middleware: Middy
    Reactive: RxJS pipelines
    Routing: @lime-energy/lambda-routers

Data Layer:
  DynamoDB (PAY_PER_REQUEST, streams enabled)
    4-10 tables per app
    GSIs for relational queries (always ALL projection)
  OpenSearch (Prospector only)
    Full-text search + geospatial (geo_point, geo_shape)
    H3 hexagonal grid aggregation
  Kinesis Streams (SDS)
    Normal + low priority streams
    Protobuf-serialized domain events

Auth Layer:
  Cognito User Pool (shared across apps)
  Cognito Identity Pool (per app)
  OAuth 2.0 code flow via AWS Amplify
  IAM roles for Lambda-to-AppSync internal mutations

External Integrations:
  Configurator (shared SAM app) - program/energy company configuration
  Sertifi (Closer) - electronic signatures
  Hubspot (Closer) - email marketing/CRM
  Sakari (Closer) - SMS notifications
  AWS Location Service (Prospector) - geocoding
```

## Multi-Tenancy Model

All data is scoped by `programId` and `energyCompanyId`:

- ApplicationsTable has GSIs on both programId and energyCompanyId
- All frontend queries require programId parameter
- ConfiguratorClient loads tenant-specific settings per program/energy company tuple
- AppSync subscriptions filtered by applicationId for multi-user scenarios
- Authorizations resolved via AppSync query checking user roles at program level

## Authentication & Authorization Flow

```
1. User lands on app --> AWS Amplify checks Cognito session
2. No session --> Redirect to Cognito Hosted UI (OAuth 2.0 code flow)
3. User authenticates --> Cognito returns authorization code
4. Amplify exchanges code for tokens (ID, Access, Refresh)
5. ID token sent to AppSync (COGNITO_USER_POOLS auth)
6. AppSync resolvers access $ctx.identity.username
7. Identity Pool provides AWS credentials for direct service access
8. Lambda functions use IAM roles for internal AppSync mutations (AWS_IAM auth)
9. Refresh token validity: 30 days
10. Mobile apps use custom scheme deep links (<app>://oauth/callback)
```

## Shared @lime-energy/* Packages

| Package | Purpose | Used In |
|---------|---------|---------|
| `@lime-energy/react-pwa` | PWA framework: useQuery, callMutation, useSubscription, CacheHandler, admin tools | Frontend (all 3) |
| `@lime-energy/react-components` | Shared React UI components | Frontend (all 3) |
| `@lime-energy/appsync-client` | LambdaAppSyncClient for HTTP mutations from Lambda to AppSync | Backend (all 3) |
| `@lime-energy/lambda-routers` | DynamodbRouter, SDSRouter for event type routing | Backend (all 3) |
| `@lime-energy/lime-models` | Protobuf domain models (Lime.Core.Applications, etc.) | Backend (all 3) |
| `@lime-energy/lime-sds-client` | SDS event client, SdsContext type | Backend (all 3) |
| `@lime-energy/sds-core` | SDS core types (SDS.Core.SdsEvent) | Backend (all 3) |
| `@lime-energy/configurator-repository` | ConfiguratorClient for program/energy company config | Backend (all 3) |
| `@lime-energy/configurator-client` | Frontend config client | Frontend (all 3) |
| `@lime-energy/measure-core` | Measurement plugin system | Frontend (Auditor) |
| `@lime-energy/measure-components` | Measurement UI components | Frontend (Auditor) |
| `@lime-energy/sw-url-converter` | Service worker URL conversion for offline | Frontend (all 3) |

## Key Dependencies (versions from Auditor)

### Frontend
- react: ^18.3.1, react-dom: ^18.3.1
- aws-amplify: ^3.3.11, aws-appsync: 4.1.9, aws-appsync-react: ^3.0.4
- @mui/material: ^5.0.6, @mui/icons-material: ^5.0.5
- @emotion/react: ^11.11.1, @emotion/styled: ^11.3.0
- formik: ^2.2.9
- react-router-dom: ^5.1.2
- graphql-tag: ^2.12.5
- rxjs: ^6.5.2
- logrocket: ^3.0.0
- typescript: ^4.9.5

### Backend
- @aws-sdk/client-dynamodb: ^3.523.0
- @aws-sdk/util-dynamodb: ^3.523.0
- @lime-energy/appsync-client: ^1.1.7
- @lime-energy/lambda-routers: (via lime-models)
- rxjs: ^6.5.4
- protobufjs: ^6.11.2
- uuid: ^9.0.1
- middy: ^0.29.0
- esbuild: ^0.13.12 (dev)
- typescript: ^5.3.3 (dev)
