## ADDED Requirements

### Requirement: Query CloudWatch logs for a Lambda function
The skill SHALL query CloudWatch Logs for a specific Lambda function with time range filtering and keyword search.

#### Scenario: Recent errors
- **WHEN** user invokes `lime-diagnose-lambda` with function name "dynamo-to-appsync" and keyword "ERROR"
- **THEN** the skill queries the function's log group for entries containing "ERROR" in the last hour and displays formatted results

#### Scenario: Custom time range
- **WHEN** user specifies a time range (e.g., "last 24 hours" or specific timestamps)
- **THEN** the skill adjusts the CloudWatch Logs Insights query accordingly

### Requirement: Trace DynamoDB stream to Lambda flow
The skill SHALL trace the event flow from a DynamoDB stream through Lambda to its target (AppSync, SDS, OpenSearch).

#### Scenario: Stream lag detection
- **WHEN** user asks to check stream health
- **THEN** the skill checks the DynamoDB stream's IteratorAge metric to detect processing lag

#### Scenario: End-to-end trace
- **WHEN** user provides a record ID
- **THEN** the skill traces: (1) DynamoDB stream event, (2) Lambda invocation logs, (3) target mutation/event delivery

### Requirement: Detect common failure patterns
The skill SHALL identify throttling, timeouts, cold starts, out-of-memory errors, and connection failures in Lambda logs.

#### Scenario: Throttling detected
- **WHEN** Lambda invocations show throttling
- **THEN** the skill reports the throttle count, affected time window, and recommends checking reserved concurrency settings

#### Scenario: Cold start analysis
- **WHEN** user asks about cold starts
- **THEN** the skill queries INIT_START log entries and reports cold start frequency, duration, and percentage of total invocations

### Requirement: Provide diagnostic scripts
The skill SHALL include shell scripts wrapping common diagnostic AWS CLI commands.

#### Scenario: Scripts available
- **WHEN** the skill is installed
- **THEN** scripts for `logs.sh` (CloudWatch query), `stream-health.sh` (iterator age), and `invocations.sh` (invocation metrics) are available
