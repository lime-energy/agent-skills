# Lambda Handler Patterns

Last verified: 2026-03-04

## Runtime & Build

- **Runtime**: Node.js 20.x
- **Language**: TypeScript
- **Bundler**: esbuild (`npm run build-local`)
- **Layer**: AWS::Serverless::LayerVersion for shared node_modules

## Directory Structure

```
backend/src/
├── common/                          # Shared library
│   ├── appsync.ts                   # LambdaAppSyncClient + sendToAppsync()
│   ├── appsync-request-factory.ts   # Build typed AppSync mutation payloads
│   ├── models.ts                    # TypeScript interfaces for DB records
│   ├── fragments.ts                 # GraphQL fragment strings for mutations
│   ├── repository.ts               # DynamoDB query helpers (SDK v3)
│   └── proto-factory.ts            # Protobuf serialization for SDS events
│
├── dynamo-to-appsync/               # DynamoDB Stream → AppSync
│   ├── index.ts                     # Handler with DynamodbRouter
│   └── <entity>-controller.ts       # Per-entity handlers
│
├── dynamo-to-sds/                   # DynamoDB Stream → Kinesis/SDS
│   ├── index.ts
│   └── <entity>-controller.ts
│
├── sds-to-appsync/                  # Kinesis/SDS → AppSync
│   ├── index.ts                     # Handler with SDSRouter
│   └── <event-type>-changed.ts      # Per-event-type handlers
│
├── dynamo-to-opensearch/            # DynamoDB Stream → OpenSearch (Prospector)
│   ├── index.ts
│   └── ...
│
└── <function-name>/                 # AppSync Lambda resolvers
    └── index.ts                     # Direct handler (no router)
```

## DynamoDB Stream Handler Pattern

The canonical pattern for processing DynamoDB streams:

```typescript
// backend/src/dynamo-to-appsync/index.ts
import { DynamodbRouter, LoggerFactory } from '@lime-energy/lambda-routers';
import { Lime } from '@lime-energy/lime-models';
import { Root } from 'protobufjs';
import { AppSyncMutation } from '@lime-energy/appsync-client';
import { catchError, mergeMap } from 'rxjs/operators';
import { appsyncDynamoErrorHandler, sendToAppsync } from '../common';
import { ApplicationAuditDetailsController } from './application-audit-details-controller';

// Protobuf enum lookups for logging
const root = Lime as unknown;
const limeRoot = root as Root;
const eventSources = limeRoot.lookupEnum('Lime.LimeSds.Events.EventSource');
const eventTypes = limeRoot.lookupEnum('Lime.LimeSds.Events.EventType');
const loggerFactory = new LoggerFactory(eventSources, eventTypes);
const defaultLogger = loggerFactory.buildSdsLogger({});

// Router setup — map stream ARNs to controllers
const dynamoRouter = new DynamodbRouter<AppSyncMutation>(loggerFactory);
const tableStreamArn = process.env.APPLICATION_AUDIT_DETAIL_TABLE_STREAM_ARN;
dynamoRouter.use(tableStreamArn, new ApplicationAuditDetailsController());

// Handler
export const handler = async (
  event: AWSLambda.DynamoDBStreamEvent,
  context: AWSLambda.Context
): Promise<void> => {
  try {
    await dynamoRouter.run(event, context)
      .pipe(
        mergeMap(sendToAppsync),
        catchError(appsyncDynamoErrorHandler)
      ).forEach((r: any) => defaultLogger.info(r));
  } catch (err) {
    const errorCode = (err.error || {}).code;
    if (errorCode === 'ECONNREFUSED' || errorCode === 'ESOCKETTIMEDOUT') {
      throw err; // retry via Lambda
    }
    defaultLogger.error('error decoding payload', err);
  }
};
```

## DynamoDB Controller Pattern

Controllers are classes with an `upsertHandler` method:

```typescript
// backend/src/dynamo-to-appsync/application-audit-details-controller.ts
import { HandlerContext } from '@lime-energy/lambda-routers';
import { EMPTY, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { AppSyncMutation } from '@lime-energy/appsync-client';
import { ExistingCondition } from '../common';
import { DbApplicationAuditDetails } from '../common/models';
import { getExistingConditionsForApplication } from '../common/repository';

export class ApplicationAuditDetailsController {
  upsertHandler({ logger, newRecord, oldRecord }: HandlerContext): Observable<AppSyncMutation> {
    const newDetails = newRecord as DbApplicationAuditDetails;
    const oldDetails = oldRecord as DbApplicationAuditDetails;

    // Guard: only process if relevant field changed
    if (!oldDetails || newDetails.effectiveDate === oldDetails.effectiveDate) return EMPTY;

    logger.debug(`Effective Date Changed. Wipe recommendations.`);

    // RxJS pipeline: query related items, map to mutations
    return getExistingConditionsForApplication(newDetails.applicationId)
      .pipe(
        map(existingCondition => {
          const mutation = `mutation UpdateExistingConditionStream($id: ID!, ...) {
            updateExistingConditionStream(id: $id, ...) {
              ${ExistingCondition}
            }
          }`;
          return {
            query: mutation,
            operationName: 'UpdateExistingConditionStream',
            variables: { id: existingCondition.id, recommendations: [], needsNewRecommendations: true }
          };
        })
      );
  }
}
```

## SDS/Kinesis Router Handler Pattern

For processing Kinesis events from the shared domain service:

```typescript
// backend/src/sds-to-appsync/index.ts
import { AppSyncMutation } from '@lime-energy/appsync-client';
import { LoggerFactory, SDSRouter } from '@lime-energy/lambda-routers';
import { Lime } from '@lime-energy/lime-models';
import { Root } from 'protobufjs';
import { mergeMap } from 'rxjs/operators';
import { sendToAppsync } from '../common';
// Import event handlers
import { applicationChanged } from './application-changed';
import { auditChanged, auditDeleted } from './audit-changed';
import { customerChanged } from './customer-changed';
import { facilityChanged } from './facility-changed';
import { documentGenerated } from './document-generated';
// ... more handlers

const root = Lime as unknown;
const limeRoot = root as Root;
const eventSources = limeRoot.lookupEnum('Lime.LimeSds.Events.EventSource');
const eventTypes = limeRoot.lookupEnum('Lime.LimeSds.Events.EventType');
const loggerFactory = new LoggerFactory(eventSources, eventTypes);
const defaultLogger = loggerFactory.buildSdsLogger({});

// Router: map event types to handlers
const sdsRouter = new SDSRouter<AppSyncMutation>(loggerFactory);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.APPLICATION_CHANGED, applicationChanged);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.FACILITY_CHANGED, facilityChanged);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.CUSTOMER_CHANGED, customerChanged);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.AUDIT_CHANGED, auditChanged);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.AUDIT_DELETED, auditDeleted);
sdsRouter.handleEvent(Lime.LimeSds.Events.EventType.DOCUMENT_GENERATED, documentGenerated);
// ... more event registrations

export const handler = async (
  event: AWSLambda.KinesisStreamEvent,
  context: AWSLambda.Context
): Promise<void> => {
  try {
    await sdsRouter.run(event, context)
      .pipe(mergeMap(sendToAppsync))
      .forEach((responses: any) =>
        defaultLogger.info(`Sending ${responses ? responses.length : 0} appsync requests`)
      );
  } catch (err) {
    const errorCode = (err.error || {}).code;
    if (errorCode === 'ECONNREFUSED' || errorCode === 'ESOCKETTIMEDOUT') {
      throw err; // retry
    }
    defaultLogger.error(err);
  }
};
```

## Common Library — AppSync Client

```typescript
// backend/src/common/appsync.ts
import { AWSError, AppSyncMutation, LambdaAppSyncClient } from '@lime-energy/appsync-client';
import { Observable, of } from 'rxjs';
import { URL } from 'url';

const appsyncUrl = process.env.APPSYNC_API;
const appsyncClient = appsyncUrl != null
  ? new LambdaAppSyncClient(
      new URL(appsyncUrl),
      30000,  // 30 second timeout
      [`STACK_ENV:${process.env.STACK_ENV}`]  // Datadog tags
    )
  : null;

export async function sendToAppsync(appsyncRequest: AppSyncMutation): Promise<void> {
  if (!appsyncRequest) return Promise.resolve();
  await appsyncClient.postMutation(appsyncRequest);
}

export function appsyncDynamoErrorHandler(err: any): Observable<any> {
  const awsError = err as AWSError;
  if (awsError.code === 'DynamoDB:ConditionalCheckFailedException') {
    return of({ message: 'ConditionalCheckFailedException silenced (expected)' });
  }
  throw err;
}
```

## Common Library — Request Factory

```typescript
// backend/src/common/appsync-request-factory.ts
import { AppSyncMutation } from '@lime-energy/appsync-client';
import { Lime } from '@lime-energy/lime-models';
import { SDS } from '@lime-energy/sds-core';
import { Application, Customer } from './fragments';

function buildSdsContext(event: SDS.Core.SdsEvent): Record<string, any> {
  return {
    eventType: event.eventType,
    eventSource: event.eventSource,
    tenant: event.tenant,
    aggregateId: event.aggregateId,
    eventId: event.eventId,
    headers: JSON.stringify({ ...event.headers })
  };
}

export function buildAppsyncRequestFromCustomer(
  customer: Lime.Core.Applications.ICustomer
): AppSyncMutation {
  if (!customer) return;
  const customerInput = {
    id: customer.id || '1',
    customerNumber: customer.customerNumber ?? null,
    company: customer.company ?? null
  };
  const query = `mutation UpdateCustomerStream($customer: CustomerInput!) {
    updateCustomerStream(customer: $customer) { ${Customer} }
  }`;
  return {
    query,
    operationName: 'UpdateCustomerStream',
    variables: { customer: customerInput }
  };
}

export function buildAppsyncRequestFromApplication(
  application: Lime.Core.Applications.IApplication,
  event: SDS.Core.SdsEvent
): AppSyncMutation {
  const sdsContext = buildSdsContext(event);
  const applicationInput = {
    id: application.id,
    programId: application.customer.programId,
    energyCompanyId: application.energyCompanyId,
    // ... map all fields with null fallbacks
    sdsContext: sdsContext
  };
  const query = `mutation UpdateApplicationStream($application: ApplicationStreamInput!) {
    updateApplicationStream(application: $application) { ${Application} }
  }`;
  return {
    query,
    operationName: 'UpdateApplicationStream',
    variables: { application: applicationInput }
  };
}
```

## Common Library — TypeScript Models

```typescript
// backend/src/common/models.ts
import { SdsContext } from '@lime-energy/lime-sds-client';

export type DbRecord = { id: string }

export type DbFacility = {
  id: string;
  facilityName: string;
  contactPerson: string;
  // ... full address fields, contact fields
}

export type DbApplication = {
  id: string;
  facility: DbFacility;
  energyCompanyId: string;
  customerId: string;
  applicationId: string;
  programId: string;
  sdsContext: SdsContext;
  // ... all fields matching DynamoDB item shape
}

// Pattern: one type per DynamoDB table item
export type DbApplicationAuditDetails = {
  applicationId: string,
  createdBy: string,
  effectiveDate: string
}
```

## SAM Function Resource Pattern

```yaml
  DynamoToAppsyncFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: dist/dynamo-to-appsync/
      Handler: index.handler
      Runtime: nodejs20.x
      MemorySize: 256
      Timeout: 30
      Layers:
        - !If [BuildModuleLayer, !Ref ModuleLayer, !Ref AWS::NoValue]
      Environment:
        Variables:
          APPSYNC_API: !GetAtt AppSyncApi.GraphQLUrl
          STACK_ENV: !Ref StackEnv
          APPLICATION_AUDIT_DETAIL_TABLE_STREAM_ARN: !GetAtt DynamoDB.Outputs.ApplicationAuditDetailsTableStreamArn
      Events:
        DynamoDBStream:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt DynamoDB.Outputs.ApplicationAuditDetailsTableStreamArn
            StartingPosition: LATEST
            BatchSize: 10
      Policies:
        - Statement:
            - Effect: Allow
              Action:
                - appsync:GraphQL
              Resource:
                - !Sub "${AppSyncApi.Arn}/*"
        - Statement:
            - Effect: Allow
              Action:
                - dynamodb:GetItem
                - dynamodb:Query
              Resource:
                - !GetAtt DynamoDB.Outputs.ExistingConditionsTableArn
                - !Join ["", [!GetAtt DynamoDB.Outputs.ExistingConditionsTableArn, "/*"]]
```

## Error Handling Convention

All Lambda handlers follow this error handling pattern:

```typescript
try {
  await router.run(event, context)
    .pipe(mergeMap(sendToAppsync), catchError(appsyncDynamoErrorHandler))
    .forEach((r) => logger.info(r));
} catch (err) {
  const errorCode = (err.error || {}).code;
  // Rethrow transient errors for Lambda retry
  if (errorCode === 'ECONNREFUSED' || errorCode === 'ESOCKETTIMEDOUT') {
    throw err;
  }
  // Log and swallow non-transient errors
  logger.error('error decoding payload', err);
}
```

Key behaviors:
- `ConditionalCheckFailedException` is silenced (expected in concurrent updates)
- `ECONNREFUSED` and `ESOCKETTIMEDOUT` are rethrown for Lambda automatic retry
- All other errors are logged and swallowed to prevent infinite retry loops
