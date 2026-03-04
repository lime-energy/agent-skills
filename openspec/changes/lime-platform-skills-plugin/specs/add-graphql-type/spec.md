## ADDED Requirements

### Requirement: Add type to GraphQL schema
The skill SHALL add a new type definition, input type, query fields, mutation fields, and subscription fields to `backend/schema.graphql`.

#### Scenario: Full entity type added
- **WHEN** user invokes `lime-add-graphql-type` with entity "Inspection" and fields (id, applicationId, status, notes, createdAt)
- **THEN** schema.graphql includes: type Inspection with all fields, input InspectionInput, Query fields (getInspection, listInspections), Mutation fields (updateInspection, putInspection, deleteInspection), and Subscription field (onUpdateInspection)

#### Scenario: Type with relationships
- **WHEN** the entity has a parent (Application) and children (InspectionItem)
- **THEN** the Inspection type includes an `items: [InspectionItem]` field and Application type gets an `inspections: [Inspection]` field

### Requirement: Generate all VTL resolvers for CRUD operations
The skill SHALL create VTL resolver pairs for all query, mutation, subscription, and field resolver operations.

#### Scenario: Complete resolver set created
- **WHEN** a new type with CRUD is added
- **THEN** the following resolver pairs are created: Query-getInspection, Query-listInspections (GSI), Mutation-updateInspection, Mutation-putInspection, Mutation-deleteInspection, Subscription-onUpdateInspection, and field resolvers for parent/child relationships

### Requirement: Generate frontend GraphQL API files
The skill SHALL update `src/api/fragments.ts`, `src/api/queries.ts`, `src/api/mutations.ts`, and `src/api/subscriptions.ts` with the new entity's operations.

#### Scenario: All API files updated
- **WHEN** the entity is added
- **THEN** fragments.ts has an Inspection fragment with all fields, queries.ts has QueryGetInspection and QueryListInspections, mutations.ts has MutationUpdateInspection/Put/Delete, and subscriptions.ts has SubscriptionInspectionUpdated

### Requirement: Run TypeScript codegen
The skill SHALL instruct the user to run `npm run generate-types` (aws-appsync-codegen) to regenerate `src/api/generated-api-types.ts` from the updated schema.

#### Scenario: Codegen reminder
- **WHEN** all schema and resolver changes are complete
- **THEN** the skill outputs a reminder to run type generation and verifies the command exists in package.json

### Requirement: Update Apollo cache model
The skill SHALL add the new entity to `src/data/models.ts` with parent, childLists, childObjects, siblings, fragment, and idName configuration.

#### Scenario: Cache model with relationships
- **WHEN** Inspection belongs to Application and has child InspectionItems
- **THEN** the models.ts entry specifies `parent: 'application'`, `childLists: ['inspectionItem']`, the fragment reference, and `idName: 'id'`

### Requirement: Add AppSync resources to SAM template
The skill SHALL add datasource, resolver resources, and any necessary IAM permissions to the main SAM template.

#### Scenario: Resolver resources in SAM
- **WHEN** resolvers are created for the new type
- **THEN** the SAM template includes AWS::AppSync::Resolver resources for each resolver pair, referencing the correct datasource and mapping templates
