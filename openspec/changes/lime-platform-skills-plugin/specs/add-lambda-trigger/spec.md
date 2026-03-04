## ADDED Requirements

### Requirement: Add EventSourceMapping to SAM template
The skill SHALL add a DynamoDB stream event source to a Lambda function in the main SAM template.

#### Scenario: Stream wired to existing function
- **WHEN** user invokes `lime-add-lambda-trigger` specifying table "InspectionsTable" and existing function "dynamo-to-appsync"
- **THEN** an Events entry is added to the function with Type DynamoDB, Stream ARN from the nested stack output, StartingPosition LATEST, and appropriate BatchSize

#### Scenario: Stream wired to new function
- **WHEN** the target function does not exist
- **THEN** the skill delegates to `lime-scaffold-lambda` to create the function first, then wires the event source

### Requirement: Create or update controller for entity
The skill SHALL create a controller file in the Lambda function's directory that handles the specific entity's stream events.

#### Scenario: Controller for AppSync target
- **WHEN** the trigger target is AppSync
- **THEN** a controller is created that transforms DynamoDB stream records into AppSync mutation payloads using `buildAppsyncRequest*` factories and `sendToAppsync`

#### Scenario: Controller for SDS target
- **WHEN** the trigger target is SDS/Kinesis
- **THEN** a controller is created that transforms DynamoDB stream records into Protobuf-serialized SDS events using the proto-factory

#### Scenario: Controller for OpenSearch target
- **WHEN** the trigger target is OpenSearch
- **THEN** a controller is created that transforms DynamoDB stream records into OpenSearch index/delete operations

### Requirement: Register controller in router
The skill SHALL register the new controller in the function's router setup (index.ts) with the correct event type.

#### Scenario: Router registration
- **WHEN** a controller for "inspection" events is created
- **THEN** the function's index.ts is updated to import the controller and register it with `router.handleEvent(EventType.INSPECTION_CHANGED, inspectionChanged)`

### Requirement: Update IAM permissions
The skill SHALL add DynamoDB stream read permissions for the new table to the Lambda function's IAM role.

#### Scenario: Stream permissions added
- **WHEN** a new stream trigger is wired
- **THEN** the function's IAM role includes dynamodb:GetRecords, dynamodb:GetShardIterator, dynamodb:DescribeStream, and dynamodb:ListStreams for the table's stream ARN
