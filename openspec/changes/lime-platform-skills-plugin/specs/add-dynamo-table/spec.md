## ADDED Requirements

### Requirement: Add table to DynamoDB nested stack
The skill SHALL add a new DynamoDB table definition to `backend/dynamodb-template.yml` following all established conventions.

#### Scenario: Table with standard configuration
- **WHEN** user invokes `lime-add-dynamo-table` with table name "InspectionsTable"
- **THEN** the table is added with BillingMode PAY_PER_REQUEST, StreamSpecification NEW_AND_OLD_IMAGES, and a primary key of `id` (S) as HASH

#### Scenario: Table with GSIs
- **WHEN** user specifies GSIs (e.g., applicationId, programId)
- **THEN** each GSI is created with KeySchema using the specified attribute as HASH, Projection ALL, and named `<attribute>-index`

#### Scenario: Table with sort key
- **WHEN** user specifies a sort key (e.g., dateCreated)
- **THEN** the primary key includes both the HASH key and the RANGE key with appropriate AttributeDefinitions

### Requirement: Add outputs to nested stack
The skill SHALL add CloudFormation Outputs for the table name, ARN, and stream ARN so the parent stack can reference them.

#### Scenario: Outputs exported
- **WHEN** the table is created
- **THEN** the dynamodb-template.yml includes Outputs for `InspectionsTableName`, `InspectionsTableArn`, and `InspectionsTableStreamArn`

### Requirement: Add AppSync datasource in parent stack
The skill SHALL add an `AWS::AppSync::DataSource` resource of type AMAZON_DYNAMODB in the main SAM template referencing the new table.

#### Scenario: Datasource references nested stack output
- **WHEN** the datasource is created
- **THEN** it uses `!GetAtt DynamoDB.Outputs.InspectionsTableName` for the table name and references the existing DynamoDB IAM role

### Requirement: Update DynamoDB IAM role permissions
The skill SHALL ensure the DynamoDB IAM role in the nested stack includes the new table's ARN in its resource list.

#### Scenario: Role updated
- **WHEN** a new table is added
- **THEN** the DynamoDBRole resource's policy includes the new table ARN and its index ARNs (`arn/index/*`) for GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, and BatchWriteItem
