## ADDED Requirements

### Requirement: Document event-driven data flow
The skill SHALL provide diagrams and descriptions of all event flow paths: user action through frontend to DynamoDB, DynamoDB streams to Lambda, Lambda to AppSync/SDS/OpenSearch.

#### Scenario: Developer queries data flow
- **WHEN** a developer asks how data flows through the system
- **THEN** the skill provides an ASCII or Mermaid diagram showing: React component -> Apollo Client -> AppSync -> VTL resolver -> DynamoDB -> Stream -> Lambda -> [AppSync subscription | SDS/Kinesis | OpenSearch]

### Requirement: Document service integration map
The skill SHALL list all AWS services and external integrations used across the platform with their roles and relationships.

#### Scenario: Developer queries service architecture
- **WHEN** a developer asks what services are involved
- **THEN** the skill provides: AppSync (API), DynamoDB (data store), Lambda (compute), Cognito (auth), S3 + CloudFront (static hosting), Kinesis/SDS (event bus), OpenSearch (search, Prospector only), Sertifi (e-sign, Closer), Hubspot/Sakari (notifications, Closer), AWS Location (geocoding, Prospector), Configurator (shared config)

### Requirement: Document multi-tenancy model
The skill SHALL explain how the platform isolates data by programId and energyCompanyId, and how the Configurator service provides tenant-specific configuration.

#### Scenario: Developer queries tenancy
- **WHEN** a developer asks about multi-tenancy
- **THEN** the skill explains: ApplicationsTable GSIs on programId and energyCompanyId, all queries require programId parameter, ConfiguratorClient loads per-tenant settings, AppSync subscriptions filtered by applicationId

### Requirement: Document authentication and authorization flow
The skill SHALL explain the Cognito User Pool + Identity Pool setup, OAuth 2.0 flow, how tokens reach AppSync, and how IAM roles are assumed.

#### Scenario: Developer queries auth
- **WHEN** a developer asks about authentication
- **THEN** the skill provides: Cognito User Pool for user management, OAuth 2.0 code flow via Amplify, ID tokens sent to AppSync (COGNITO_USER_POOLS auth), Identity Pool provides AWS credentials for IAM auth, Lambda uses IAM roles for internal AppSync mutations

### Requirement: Document per-application differences
The skill SHALL clearly identify what is unique to each application versus what is shared across all three.

#### Scenario: Developer queries app differences
- **WHEN** a developer asks what's different about Prospector
- **THEN** the skill explains: Prospector adds OpenSearch for full-text and geospatial search, uses H3 hexagonal grid aggregation, has AWS Location Service integration, uses React Context providers extensively, and makes direct API Gateway calls for search (not just GraphQL)

### Requirement: Provide architecture decision records
The skill SHALL document key architectural decisions that apply across the platform (e.g., why PAY_PER_REQUEST, why VTL over Lambda resolvers for simple operations, why RxJS in Lambda handlers).

#### Scenario: Developer queries decision
- **WHEN** a developer asks why VTL resolvers are used instead of Lambda resolvers
- **THEN** the skill explains: VTL resolvers have lower latency (no cold start), lower cost (no Lambda invocation), and are sufficient for simple CRUD operations; Lambda resolvers are used only when business logic is required
