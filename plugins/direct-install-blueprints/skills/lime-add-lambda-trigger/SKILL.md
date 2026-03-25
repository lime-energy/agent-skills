---
name: lime-add-lambda-trigger
description: "Wire a DynamoDB stream to a Lambda function with controller and router registration. Use when connecting a new or existing table's stream events to a Lambda handler."
---

# Add Lambda Trigger

Wire a DynamoDB table's stream to a Lambda function, creating or updating the controller and router registration.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/lambda-patterns.md` — Controller patterns, router setup
- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — EventSourceMapping, SAM function events

## Inputs

- **Source table** (e.g., `InspectionsTable`)
- **Target function** (e.g., `dynamo-to-appsync`)
- **Entity type** (e.g., `inspection`)
- **Target type** — `appsync`, `sds`, or `opensearch`

## What Gets Created/Updated

### 1. Event Source in SAM Template

Add to the function's Events section:

```yaml
InspectionsStream:
  Type: DynamoDB
  Properties:
    Stream: !GetAtt DynamoDB.Outputs.InspectionsTableStreamArn
    StartingPosition: LATEST
    BatchSize: 10
```

### 2. Controller File

**For AppSync target** (`<entity>-controller.ts`):
```typescript
import { buildAppsyncRequestUpdate } from '../common/appsync-request-factory';
export function inspectionChanged(record: DynamoDBRecord): AppSyncMutation {
  return buildAppsyncRequestUpdate(record, 'updateInspectionStream');
}
```

**For SDS target**:
```typescript
import { buildSdsEvent } from '../common/sds-factory';
export function inspectionChanged(record: DynamoDBRecord): SdsEvent {
  return buildSdsEvent(record, SdsEventType.INSPECTION_CHANGED);
}
```

**For OpenSearch target**:
```typescript
export function inspectionChanged(record: DynamoDBRecord): OpenSearchAction {
  // index or delete based on eventName
}
```

### 3. Router Registration

Update the function's `index.ts`:

```typescript
import { inspectionChanged } from './inspection-controller';
router.handleEvent(EventType.INSPECTION_CHANGED, inspectionChanged);
```

### 4. IAM Permissions

Add to function's IAM role:
```yaml
- Effect: Allow
  Action:
    - dynamodb:GetRecords
    - dynamodb:GetShardIterator
    - dynamodb:DescribeStream
    - dynamodb:ListStreams
  Resource: !GetAtt DynamoDB.Outputs.InspectionsTableStreamArn
```

## Notes

- If the target function doesn't exist, delegate to `lime-scaffold-lambda` first
- The `updateInspectionStream` mutation name follows the `update<Type>Stream` convention for stream-originated mutations
- Stream mutations use `<Type>StreamInput` input types in the GraphQL schema
