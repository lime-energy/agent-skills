## ADDED Requirements

### Requirement: Generate VTL request/response template pair
The skill SHALL create VTL mapping templates in `backend/resolvers/` following the naming convention `<Type>-<field>.request` and `<Type>-<field>.response` or `<Operation>-<operationName>.request/response`.

#### Scenario: GetItem resolver generated
- **WHEN** user requests a get-by-ID resolver for type "Inspection"
- **THEN** the skill creates `Query-getInspection.request` with a DynamoDB GetItem operation using `$ctx.args.id` and `Query-getInspection.response` returning `$util.toJson($ctx.result)`

#### Scenario: Query (GSI) resolver generated
- **WHEN** user requests a list resolver querying by applicationId
- **THEN** the skill creates `Query-listInspections.request` with a DynamoDB Query operation on the `applicationId-index` GSI

#### Scenario: UpdateItem resolver generated
- **WHEN** user requests an update resolver
- **THEN** the skill creates `Mutation-updateInspection.request` with expression-based UpdateItem using SET expressions built from `$ctx.args`

#### Scenario: PutItem resolver generated
- **WHEN** user requests a create resolver
- **THEN** the skill creates `Mutation-putInspection.request` with a DynamoDB PutItem operation and auto-generated ID via `$util.autoId()`

#### Scenario: DeleteItem resolver generated
- **WHEN** user requests a delete resolver
- **THEN** the skill creates `Mutation-deleteInspection.request` with a DynamoDB DeleteItem operation and a condition expression `attribute_exists(id)`

#### Scenario: Field resolver generated
- **WHEN** user requests a field resolver for `Inspection.items`
- **THEN** the skill creates `Inspection-items.request` querying the items table GSI by `inspectionId` and `Inspection-items.response` returning `$util.toJson($ctx.result.items)`

### Requirement: Add AppSync datasource if needed
The skill SHALL add a DynamoDB or Lambda datasource to the main SAM template if one does not already exist for the target table.

#### Scenario: New DynamoDB datasource
- **WHEN** the resolver targets a table without an existing datasource
- **THEN** an `AWS::AppSync::DataSource` of type AMAZON_DYNAMODB is added with the table name and DynamoDB IAM role

### Requirement: Add resolver resource to SAM template
The skill SHALL add `AWS::AppSync::Resolver` resources to the main SAM template for each resolver pair created.

#### Scenario: Resolver resource added
- **WHEN** a Query-getInspection resolver pair is created
- **THEN** the SAM template gets an AppSync Resolver resource with TypeName "Query", FieldName "getInspection", and references to the request/response mapping templates

### Requirement: Update GraphQL schema
The skill SHALL add or update types, queries, mutations, and subscriptions in `backend/schema.graphql` as needed for the resolver.

#### Scenario: Schema type added
- **WHEN** a resolver for a new type "Inspection" is created
- **THEN** `backend/schema.graphql` is updated with the Inspection type definition, and the Query/Mutation/Subscription types include the new fields
