# Lime Energy Naming & Code Conventions

Last verified: 2026-03-04

## GraphQL Naming

| Category | Convention | Examples |
|----------|-----------|----------|
| Types | PascalCase | `Application`, `ConditionInstance`, `ExistingCondition` |
| Input Types | `<Type>Input` | `ApplicationInput`, `ApplicationStreamInput`, `FacilityStreamInput` |
| Read-only Types | `<Type>ReadOnlyFields` | `ApplicationReadOnlyFields` |
| Queries | `get<Type>`, `list<Types>` | `getApplication`, `listApplications`, `batchGetApplications` |
| Mutations | `update<Type>`, `put<Type>`, `delete<Type>` | `updateApplication`, `putRoom`, `deleteRoom` |
| Stream Mutations | `update<Type>Stream` | `updateApplicationStream`, `updateExistingConditionStream` |
| Subscriptions | `on<Action><Type>` | `onUpdateApplication`, `onPutRoom`, `onUpdateExistingCondition` |
| Fragments | `<Type>` or `<Type>Fragment` | `Application`, `ConditionInstanceFragment` |
| Auth Directives | `@aws_cognito_user_pools @aws_iam` | Applied to types needing both auth modes |

## File & Directory Naming

| Location | Convention | Examples |
|----------|-----------|----------|
| Backend handlers | kebab-case directories | `dynamo-to-appsync/`, `sds-to-appsync/`, `get-program-context/` |
| Backend handler entry | `index.ts` | `backend/src/dynamo-to-appsync/index.ts` |
| Backend controllers | kebab-case | `application-controller.ts`, `scope-controller.ts` |
| Backend common lib | kebab-case | `appsync.ts`, `models.ts`, `fragments.ts`, `appsync-request-factory.ts` |
| VTL resolvers | `<Type>-<field>.request/response` | `Query-getApplication.request`, `Mutation-updateScope.request` |
| Frontend API files | nouns | `queries.ts`, `mutations.ts`, `subscriptions.ts`, `fragments.ts` |
| Frontend components | kebab-case `.tsx` | `closer-route-handler.tsx`, `main-view.tsx` |
| Frontend context | kebab-case with `-provider` | `opensearch-provider.tsx`, `userstate-provider.tsx` |
| Frontend services | kebab-case with `-service` | `application-service.ts`, `search-service.ts` |
| CloudFormation | kebab-case `.yml` | `auditor.yml`, `dynamodb-template.yml`, `cognito-template.yml` |
| CI/CD workflows | kebab-case `.yml` | `ci.yml`, `deploy.yml`, `lint-cfn.yml` |

## Frontend API File Conventions

### Fragments (`src/api/fragments.ts`)
```typescript
// Each fragment is a named gql export
// Fragments compose via template literals
export const Room = gql`
fragment Room on Room {
  id
  label
  applicationId
  floorId
  // ... all fields
}`;

export const Floor = gql`
fragment Floor on Floor {
  id
  label
  applicationId
  rooms {
    ...Room
  }
}${Room}`;  // <-- compose child fragment via template literal
```

### Queries (`src/api/queries.ts`)
```typescript
// Prefix: Query
// Import fragments from ./
export const QueryGetApplication = gql`
query GetApplication($id: ID!) {
  getApplication(id: $id) {
    ...Application
  }
}${Application}`;

export const QueryGetAvailablePrograms = gql`
query QueryGetAvailablePrograms {
  getAvailablePrograms {
    ...Program
  }
}${Program}`;
```

### Mutations (`src/api/mutations.ts`)
```typescript
// Prefix: Mutation
// Typed variables, returns fragment
export const MutationUpdateScope = gql`
    mutation UpdateScope(
        $id: ID!
        $applicationId: ID!
        $startDate: String
        $endDate: String
        $category: String!
        $name: String!
    ){
        updateScope(
            id: $id
            applicationId: $applicationId
            startDate: $startDate
            endDate: $endDate
            category: $category
            name: $name
        ){
            ...Scope
        }
    }${Scope}
`;
```

### Subscriptions (`src/api/subscriptions.ts`)
```typescript
// Prefix: Subscription
// Filtered by resource ID
export const SubscriptionApplicationUpdated = gql`
subscription ApplicationUpdatedSub($id: ID) {
    onUpdateApplication(id: $id) {
        ...Application
    }
}${Application}`;

export const SubscriptionScopeUpdate = gql`
    subscription ScopeUpdate($applicationId: ID!) {
        onUpdateScope(applicationId: $applicationId) {
            ...BasicScope
        }
    }${BasicScope}
`;
```

## Apollo Cache Model Convention (`src/data/models.ts`)

```typescript
import { CacheHandler, getModel, Model } from '@lime-energy/react-pwa/dist';

export const MODELS: Record<string, Model> = {
  // Top-level entity with children
  application: {
    fragment: Application,
    fragmentName: 'Application',
    idName: 'applicationId',
    childLists: ['scope', 'floor', 'existingCondition', 'controlPoint'],
    childObjects: ['facility', 'customer', 'auditDetails'],
    siblings: []
  },
  // Child entity with parent
  scope: {
    fragment: Scope,
    fragmentName: 'Scope',
    idName: 'scopeId',
    listName: 'scopes',        // name in parent's childLists
    parent: 'application',
    childLists: ['conditionInstance'],
    childObjects: [],
    siblings: []
  },
  // Using getModel() shorthand
  room: getModel({
    fragment: Room,
    fragmentName: 'Room',
    idName: 'roomId',
    listName: 'rooms',
    parent: 'floor',
  }),
};

export const cacheHandler = new CacheHandler(MODELS);
```

## Repository Pattern (`src/repository.ts`)

```typescript
import { callMutation } from '@lime-energy/react-pwa/dist';
import { MODELS, cacheHandler } from './data/models';

class Repository {
  // Simple mutation (no custom cache logic)
  updateRoom(room, client) {
    return callMutation({
      document: MutationPutRoom,
      model: MODELS.room,
      dataName: 'putRoom',
      mutationType: 'update',
      variables: room,
      cacheHandler,
      client
    });
  }

  // Complex mutation with optimistic updates + manual cache management
  updateScope = (scope, client) => {
    const applicationData = cacheHandler.getValueFromCache(
      scope.applicationId, MODELS.application, client
    );
    return callMutation({
      document: MutationUpdateScope,
      model: MODELS.scope,
      dataName: 'updateScope',
      variables: scope,
      mutationType: 'update',
      getOptimisticResponseValues: (values) => ({
        updateScope: { ...scope, __typename: 'Scope' }
      }),
      update: (data, cache) => {
        // Manual cache update for parent-child relationships
        client.writeFragment({
          id: `Application:${scope.applicationId}`,
          fragment: Application,
          fragmentName: 'Application',
          data: applicationData
        });
      },
      client,
      cacheHandler
    });
  };
}
```

## CloudFormation Conventions

- Main template: `backend/<app-name>.yml` (1,300-1,700 lines)
- Transform: `AWS::Serverless-2016-10-31`
- Nested stacks via `AWS::CloudFormation::Stack` with `TemplateURL: ./<template>.yml`
- External SAM apps via `AWS::Serverless::Application` with S3 location
- Parameters: PascalCase (`ApiName`, `AppStage`, `StackEnv`, `UserPoolId`)
- Resource logical IDs: PascalCase by purpose (`ApplicationsTable`, `DynamoDBRole`, `AppSyncApi`)
- Conditions use `!Equals`, `!Not` for feature flags (`EnableLocalUserPoolClients`)
- Frontend config substitution: `__VARIABLE__` placeholders replaced at deploy time

## Backend Code Conventions

- All handlers export `handler` as async function
- DynamoDB routers: `new DynamodbRouter<AppSyncMutation>(loggerFactory)`
- SDS routers: `new SDSRouter<AppSyncMutation>(loggerFactory)`
- Controllers are classes with `upsertHandler` method (DynamoDB) or exported functions (SDS)
- RxJS pipelines: `router.run(event, context).pipe(mergeMap(sendToAppsync)).forEach(...)`
- Error handling: catch ECONNREFUSED/ESOCKETTIMEDOUT and rethrow for retry; silence ConditionalCheckFailedException
- Protobuf via `@lime-energy/lime-models` for SDS event serialization
- Environment variables: TABLE_STREAM_ARN, APPSYNC_API, STACK_ENV, REGION
