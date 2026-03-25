---
name: lime-scaffold-lambda
description: "Scaffold a Lambda function with router pattern, controllers, IAM role, and SAM template entry. Use when creating new Lambda handlers for DynamoDB streams, Kinesis/SDS events, or AppSync resolvers."
---

# Scaffold Lambda Function

Create a new Lambda function with the Lime Energy handler pattern: router, controllers, IAM role, and SAM template configuration.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/lambda-patterns.md` — Handler, router, controller patterns
- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — SAM function resource
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — File naming, backend conventions

## Inputs

- **Function name** (kebab-case, e.g., `dynamo-to-notifications`)
- **Event source type** — `dynamodb-stream`, `kinesis`, or `appsync-resolver`
- **Entity types handled** (e.g., `inspection`, `customer`)
- **Target** — `appsync`, `sds`, `opensearch`, or custom

## What Gets Created

### 1. Handler (`backend/src/<function-name>/index.ts`)

DynamoDB stream handler:
```typescript
import { DynamodbRouter } from '@lime-energy/lambda-routers';
import { AppSyncMutation } from '../common/models';
import { sendToAppsync } from '../common/appsync';
import { inspectionChanged } from './inspection-controller';

const router = new DynamodbRouter<AppSyncMutation>(loggerFactory);
router.handleEvent(EventType.INSPECTION_CHANGED, inspectionChanged);

export const handler = async (event, context) => {
  await router.run(event, context)
    .pipe(mergeMap(sendToAppsync))
    .forEach(result => logger.info('Sent', result));
};
```

### 2. Controllers (`backend/src/<function-name>/<entity>-controller.ts`)

```typescript
import { buildAppsyncRequestUpdate } from '../common/appsync-request-factory';

export function inspectionChanged(record: DynamoDBRecord): AppSyncMutation {
  return buildAppsyncRequestUpdate(record, 'updateInspectionStream');
}
```

### 3. SAM Function Resource (`backend/<app>.yml`)

```yaml
DynamoToNotifications:
  Type: AWS::Serverless::Function
  Properties:
    Handler: src/dynamo-to-notifications/index.handler
    Runtime: nodejs20.x
    MemorySize: 256
    Timeout: 30
    Environment:
      Variables:
        APPSYNC_API: !GetAtt AppSyncApi.GraphQLUrl
        STACK_ENV: !Ref StackEnv
        REGION: !Ref AWS::Region
    Policies:
      - Statement:
          - Effect: Allow
            Action: appsync:GraphQL
            Resource: !Sub "${AppSyncApi.Arn}/*"
    Events:
      InspectionsStream:
        Type: DynamoDB
        Properties:
          Stream: !GetAtt DynamoDB.Outputs.InspectionsTableStreamArn
          StartingPosition: LATEST
          BatchSize: 10
```

### 4. IAM Permissions

Minimum permissions based on event source and target:
- **DynamoDB stream source**: GetRecords, GetShardIterator, DescribeStream, ListStreams on table stream ARN
- **AppSync target**: appsync:GraphQL on API ARN
- **SDS/Kinesis target**: kinesis:PutRecord, kinesis:PutRecords on stream ARN
- **DynamoDB target**: GetItem, PutItem, Query on target table ARN

## Event Source Types

| Type | Router | Import |
|------|--------|--------|
| `dynamodb-stream` | `DynamodbRouter` | `@lime-energy/lambda-routers` |
| `kinesis` | `SDSRouter` | `@lime-energy/lambda-routers` |
| `appsync-resolver` | None (direct handler) | N/A |
