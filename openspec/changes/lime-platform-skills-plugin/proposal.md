## Why

The Lime Energy platform comprises three applications (Auditor, Closer, Prospector) that share 95% architectural consistency — same monorepo structure, same AWS stack (AppSync + DynamoDB + Lambda + SAM), same internal libraries (@lime-energy/*), and same build/deploy pipelines. Despite this consistency, there is no codified knowledge base or automation to help developers scaffold new features, maintain existing sites, or operate in production. Every new DynamoDB table, GraphQL type, Lambda function, or VTL resolver requires manually replicating patterns across CloudFormation templates, backend code, and frontend API layers. A comprehensive skills plugin would encode these patterns as reusable, executable knowledge.

## What Changes

- Create a **lime-platform** agent skills plugin containing 15 skills organized into four categories
- **Creation skills** (4): scaffold-site, scaffold-lambda, scaffold-frontend, scaffold-resolver — generate new code and infrastructure following established patterns
- **Maintenance skills** (4): add-dynamo-table, add-graphql-type, add-lambda-trigger, update-cfn-stack — extend existing applications with proper cross-file coordination
- **Operations skills** (5): deploy-site, diagnose-lambda, validate-stack, audit-permissions, review-pr — support deployment, monitoring, validation, and code review
- **Reference skills** (2): lime-conventions, lime-architecture — living documentation of naming patterns, architectural decisions, and system design
- Bundle all skills as a single installable plugin for the team

## Capabilities

### New Capabilities
- `scaffold-site`: Generate a complete new Lime Energy application from template (full monorepo with backend/, src/, cordova/, .github/, SAM templates, nested stacks, React PWA)
- `scaffold-lambda`: Add a new Lambda function with event source wiring, IAM role, RxJS router pattern, and common library integration
- `scaffold-frontend`: Add a frontend feature with component tree, GraphQL API files (query/mutation/subscription/fragment), Apollo cache model, and repository wrapper
- `scaffold-resolver`: Add an AppSync VTL resolver pair with datasource configuration, schema updates, and SAM template integration
- `add-dynamo-table`: Add a DynamoDB table to dynamodb-template.yml following conventions (PAY_PER_REQUEST, streams, GSIs) with AppSync datasource and IAM
- `add-graphql-type`: Full entity lifecycle from schema type through resolvers, frontend API files, TypeScript codegen, and cache model configuration
- `add-lambda-trigger`: Wire a DynamoDB stream to a Lambda function targeting AppSync, SDS/Kinesis, or OpenSearch
- `update-cfn-stack`: Safely modify CloudFormation nested stacks with breaking change detection and cross-stack reference management
- `deploy-site`: Orchestrate full deployment: cfn-include preprocessing, SAM package, CloudFormation deploy, S3 upload, CloudFront invalidation
- `diagnose-lambda`: Production troubleshooting via CloudWatch log queries, DDB stream tracing, throttle/error/cold-start detection
- `validate-stack`: Pre-deployment validation: CFN lint, VTL syntax check, schema-resolver consistency, IAM completeness
- `audit-permissions`: IAM security review mapping functions to roles, identifying over-permissions, validating Cognito configuration
- `review-pr`: Domain-aware code review understanding Lime Energy patterns, cross-file dependencies, and subscription wiring
- `lime-conventions`: Living reference for naming patterns, GraphQL conventions, CloudFormation patterns, frontend/backend code organization
- `lime-architecture`: System design reference with event flow diagrams, service integration map, data models, auth flow, multi-tenancy model

### Modified Capabilities

(none — no existing specs)

## Impact

- **New files**: 15 SKILL.md files + supporting reference documents and templates, organized as a plugin in the agent-skills registry
- **Dependencies**: Skills reference @lime-energy/* internal packages (react-pwa, lambda-routers, appsync-client, lime-models, configurator-repository)
- **Affected systems**: All three repositories (auditor, closer, prospector) — skills must work across all of them
- **External tools**: AWS CLI, SAM CLI, cfn-include, esbuild, aws-appsync-codegen, GitHub Actions
- **Team workflow**: Developers install the plugin and invoke skills via slash commands during daily development
