## ADDED Requirements

### Requirement: Check cross-file consistency for schema changes
The skill SHALL verify that GraphQL schema changes are accompanied by corresponding resolver, SAM template, and frontend API file updates.

#### Scenario: Schema change without resolvers
- **WHEN** a PR adds a new field to schema.graphql but no resolver pair is created
- **THEN** the skill flags the missing resolver in the review

#### Scenario: Schema change without frontend API
- **WHEN** a PR adds a new query/mutation to the schema but doesn't update `src/api/queries.ts` or `src/api/mutations.ts`
- **THEN** the skill flags the missing frontend API update

### Requirement: Validate DynamoDB table patterns
The skill SHALL check that any new DynamoDB tables in a PR follow the established conventions.

#### Scenario: Convention violation
- **WHEN** a new table uses PROVISIONED billing instead of PAY_PER_REQUEST
- **THEN** the skill flags the deviation and recommends PAY_PER_REQUEST

#### Scenario: Missing stream configuration
- **WHEN** a new table does not enable DynamoDB Streams
- **THEN** the skill flags the omission (all Lime tables use streams)

### Requirement: Verify subscription wiring
The skill SHALL check that real-time features have complete subscription wiring from DynamoDB stream through Lambda to AppSync and frontend.

#### Scenario: Incomplete subscription chain
- **WHEN** a PR adds an AppSync subscription type but no Lambda function sends mutations to it
- **THEN** the skill flags the incomplete real-time data flow

### Requirement: Check naming convention compliance
The skill SHALL verify that new code follows Lime Energy naming conventions for types, fields, files, and resources.

#### Scenario: Naming violation
- **WHEN** a new GraphQL query uses `fetchInspection` instead of `getInspection`
- **THEN** the skill flags it and recommends the `get*` prefix convention

#### Scenario: File naming violation
- **WHEN** a new component file uses `InspectionDetail.tsx` instead of `inspection-detail.tsx` for a utility (or vice versa for components)
- **THEN** the skill flags the inconsistency

### Requirement: Validate cache model updates
The skill SHALL check that new or modified entities have corresponding Apollo cache model entries in `src/data/models.ts`.

#### Scenario: Missing cache model
- **WHEN** a PR adds a new GraphQL type with frontend queries but no cache model entry
- **THEN** the skill flags the missing entry and its likely parent/child configuration
