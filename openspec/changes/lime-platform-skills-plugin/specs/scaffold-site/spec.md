## ADDED Requirements

### Requirement: Generate complete monorepo structure
The skill SHALL generate a new Lime Energy application with the standard monorepo directory layout: `backend/`, `src/`, `cordova/`, `public/`, `tools/`, `.github/workflows/`.

#### Scenario: New site scaffolding
- **WHEN** user invokes `lime-scaffold-site` with an application name (e.g., "inspector")
- **THEN** the skill creates the full directory tree matching the Auditor/Closer/Prospector pattern

#### Scenario: Naming convention applied
- **WHEN** the site is scaffolded with name "inspector"
- **THEN** the main SAM template is named `backend/inspector.yml`, the AppSync API uses the name pattern, and all CloudFormation resource logical IDs use the app name as prefix

### Requirement: Generate main SAM template with AppSync and CloudFront
The skill SHALL create a `backend/<app-name>.yml` SAM template with AppSync API (Cognito + IAM auth), S3 bucket, CloudFront distribution, and references to nested stacks.

#### Scenario: SAM template contains required resources
- **WHEN** the main SAM template is generated
- **THEN** it includes: AWS::AppSync::GraphQLApi, AWS::AppSync::GraphQLSchema, S3 website bucket, CloudFront distribution with OAI, and nested stack references for DynamoDB and Cognito

#### Scenario: Parameters match established pattern
- **WHEN** the main SAM template is generated
- **THEN** it includes parameters for ApiName, AppStage, UserPoolId, UserPoolDomain, StackEnv, and FullDomainName

### Requirement: Generate nested stack templates
The skill SHALL create `backend/dynamodb-template.yml` with an ApplicationsTable and CustomersTable, and `backend/cognito-template.yml` with Identity Pool and User Pool Client configuration.

#### Scenario: DynamoDB template follows conventions
- **WHEN** the DynamoDB nested stack is generated
- **THEN** all tables use PAY_PER_REQUEST billing, enable streams with NEW_AND_OLD_IMAGES, and the ApplicationsTable has GSIs on programId and energyCompanyId

#### Scenario: Cognito template follows conventions
- **WHEN** the Cognito nested stack is generated
- **THEN** it includes an IdentityPool, UserPoolClient with OAuth 2.0 code flow, and AuthorizedRole/UnAuthorizedRole IAM roles

### Requirement: Generate base GraphQL schema and resolvers
The skill SHALL create `backend/schema.graphql` with Application and Customer types, and VTL resolver pairs in `backend/resolvers/` for CRUD operations.

#### Scenario: Schema includes base types
- **WHEN** the schema is generated
- **THEN** it includes Application type, Customer type, Query type with getApplication and listApplications, Mutation type with updateApplication, and Subscription type with onUpdateApplication

### Requirement: Scaffold React PWA frontend
The skill SHALL create the `src/` directory with a React 18 + TypeScript setup using @lime-energy/react-pwa, MUI, and aws-appsync.

#### Scenario: Frontend structure matches pattern
- **WHEN** the frontend is scaffolded
- **THEN** it includes `src/api/` (queries.ts, mutations.ts, subscriptions.ts, fragments.ts), `src/components/root/`, `src/components/common/`, `src/data/models.ts`, and `src/repository.ts`

### Requirement: Generate CI/CD workflows
The skill SHALL create all 6 GitHub Actions workflow files matching the established pipeline pattern.

#### Scenario: All workflows present
- **WHEN** workflows are generated
- **THEN** `.github/workflows/` contains ci.yml, deploy.yml, deploy-ios.yml, lint-cfn.yml, lint-code.yml, and release-manager.yml

### Requirement: Generate build configuration
The skill SHALL create package.json files for both frontend and backend, plus craco.config.js, tsconfig.json, jest.config.js, and .releaserc.

#### Scenario: Build tools configured
- **WHEN** build configuration is generated
- **THEN** the backend package.json includes build (tsc), build-local (esbuild), and preprocess-cfn scripts, and the frontend package.json includes craco build and generate-types scripts
