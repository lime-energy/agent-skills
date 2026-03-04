## ADDED Requirements

### Requirement: Document GraphQL naming conventions
The skill SHALL provide a complete reference for GraphQL naming patterns used across all Lime Energy applications.

#### Scenario: Developer queries convention
- **WHEN** a developer asks about naming a new GraphQL query
- **THEN** the skill provides: types use PascalCase, queries use `get<Type>`/`list<Types>`, mutations use `update<Type>`/`put<Type>`/`delete<Type>`, subscriptions use `on<Action><Type>`, fragments use `<Type>` or `<Type>Fragment`, inputs use `<Type>Input`

### Requirement: Document file and directory naming conventions
The skill SHALL provide naming rules for all file types across frontend and backend.

#### Scenario: Developer queries file naming
- **WHEN** a developer asks how to name a new file
- **THEN** the skill provides: component files use kebab-case (e.g., `inspection-detail.tsx`), backend handlers use kebab-case directories (e.g., `dynamo-to-appsync/`), VTL resolvers use `<Type>-<field>.request/response`, API files use descriptive nouns (queries.ts, mutations.ts)

### Requirement: Document CloudFormation conventions
The skill SHALL provide patterns for SAM template organization, resource naming, parameter naming, and nested stack structure.

#### Scenario: Developer queries CFN pattern
- **WHEN** a developer asks about CloudFormation conventions
- **THEN** the skill provides: main template is `backend/<app>.yml`, nested stacks for DynamoDB and Cognito, parameters use PascalCase, resources use PascalCase logical IDs prefixed by purpose, all DynamoDB tables use PAY_PER_REQUEST with streams

### Requirement: Document frontend code organization patterns
The skill SHALL provide the standard directory structure, Apollo cache patterns, repository pattern, and component patterns.

#### Scenario: Developer queries frontend structure
- **WHEN** a developer asks about frontend organization
- **THEN** the skill provides: API files in `src/api/`, components in `src/components/root/` and `src/components/common/`, data models in `src/data/models.ts`, repository wrappers in `src/repository.ts`, fragment-based GraphQL queries, optimistic Apollo cache updates

### Requirement: Document backend code organization patterns
The skill SHALL provide the standard Lambda handler structure, router pattern, common library usage, and dependency conventions.

#### Scenario: Developer queries backend structure
- **WHEN** a developer asks about backend organization
- **THEN** the skill provides: handlers in `backend/src/<function>/index.ts`, controllers per entity type, common library in `backend/src/common/`, RxJS pipelines for async processing, @lime-energy/lambda-routers for event routing, Middy for middleware

### Requirement: Include examples from actual codebase
The skill SHALL reference actual code patterns from Auditor, Closer, and Prospector as canonical examples.

#### Scenario: Real example provided
- **WHEN** a developer asks for an example of a VTL resolver
- **THEN** the skill shows patterns extracted from the actual repos (e.g., Query-getApplication, Mutation-updateConditionInstance) with explanatory annotations
