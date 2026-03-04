## ADDED Requirements

### Requirement: Generate Lambda function handler with router pattern
The skill SHALL create a Lambda handler in `backend/src/<function-name>/index.ts` using the @lime-energy/lambda-routers package and RxJS for reactive stream processing.

#### Scenario: Stream handler scaffolded
- **WHEN** user invokes `lime-scaffold-lambda` with function name "dynamo-to-notifications" and event source type "dynamodb-stream"
- **THEN** the skill creates `backend/src/dynamo-to-notifications/index.ts` with a DynamoDBRouter, event handler registration, and RxJS pipeline

#### Scenario: AppSync resolver handler scaffolded
- **WHEN** user specifies event source type "appsync-resolver"
- **THEN** the handler is structured as a direct Lambda resolver without the router pattern, returning a typed response

### Requirement: Add function definition to SAM template
The skill SHALL add an `AWS::Serverless::Function` resource to the main SAM template with proper runtime, memory, timeout, environment variables, and event source mapping.

#### Scenario: DynamoDB stream event source
- **WHEN** function is wired to a DynamoDB stream
- **THEN** the SAM template includes a DynamoDB event source with the table's stream ARN, StartingPosition LATEST, and BatchSize configuration

#### Scenario: Kinesis event source
- **WHEN** function is wired to a Kinesis stream
- **THEN** the SAM template includes a Kinesis event source with the stream ARN and StartingPosition LATEST

#### Scenario: AppSync data source
- **WHEN** function is an AppSync resolver
- **THEN** the SAM template includes an AWS::AppSync::DataSource of type AWS_LAMBDA and an AWS::AppSync::Resolver referencing it

### Requirement: Create IAM role with least-privilege permissions
The skill SHALL generate an IAM role for the Lambda function with only the permissions required for its specific event source and targets.

#### Scenario: DynamoDB stream handler permissions
- **WHEN** function reads from DynamoDB streams and writes to AppSync
- **THEN** the IAM role includes dynamodb:GetRecords, dynamodb:GetShardIterator, dynamodb:DescribeStream, dynamodb:ListStreams for the source table, and appsync:GraphQL for the AppSync API

### Requirement: Generate controller files for event routing
The skill SHALL create controller files in `backend/src/<function-name>/` for each entity type the function handles.

#### Scenario: Controller generated
- **WHEN** user specifies the function handles "application" and "customer" events
- **THEN** the skill creates `application-controller.ts` and `customer-controller.ts` with typed handler functions registered in the router

### Requirement: Add common library imports
The skill SHALL import and use shared utilities from `backend/src/common/` including appsync.ts, models.ts, and fragments.ts as needed.

#### Scenario: AppSync target uses common client
- **WHEN** the function targets AppSync
- **THEN** the handler imports `sendToAppsync` from `../common/appsync` and uses `buildAppsyncRequest*` factories from `../common/appsync-request-factory`
