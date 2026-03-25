# Frontend Patterns

Last verified: 2026-03-04

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | React + TypeScript | 18.3.1 / 4.9.5 |
| Build | Create React App + Craco | 5.0.1 |
| UI | MUI (Material-UI) | 5.0.6 |
| Styling | Emotion (CSS-in-JS) | 11.x |
| GraphQL | aws-appsync (Apollo-based) + AWS Amplify | 4.1.9 / 3.3.11 |
| Forms | Formik + Yup | 2.2.9 |
| Routing | react-router-dom | 5.1.2 |
| PWA | @lime-energy/react-pwa | 1.2.x |
| Mobile | Cordova (iOS wrapper) | - |
| Monitoring | LogRocket + Datadog | 3.0.0 |

## Directory Structure

```
src/
├── api/                          # GraphQL operations
│   ├── fragments.ts              # Reusable GraphQL fragments
│   ├── queries.ts                # Query definitions (QueryGet*, QueryList*)
│   ├── mutations.ts              # Mutation definitions (Mutation*)
│   ├── subscriptions.ts          # Subscription definitions (Subscription*)
│   ├── generated-api-types.ts    # Auto-generated TS types from schema
│   └── index.ts                  # Re-exports all fragments + types
│
├── components/
│   ├── root/                     # Main application pages
│   │   ├── main.tsx              # Primary interface
│   │   ├── <feature>/            # Feature-specific components
│   │   └── forms/                # Form components (Formik)
│   ├── common/                   # Shared/reusable components
│   └── navigation/               # Bottom nav bar
│
├── context/                      # React Context providers (Prospector pattern)
│   ├── opensearch-provider.tsx
│   ├── userstate-provider.tsx
│   ├── program-provider.tsx
│   └── configset-provider.tsx
│
├── services/                     # Business logic (Prospector pattern)
│   ├── application-service.ts
│   └── search-service.ts
│
├── data/
│   └── models.ts                 # Apollo cache model configuration
│
├── hooks/                        # Custom React hooks
├── types/                        # TypeScript interfaces
├── assets/                       # Images, CSS
├── repository.ts                 # Apollo mutation wrappers
├── routes.tsx                    # Route definitions
└── index.tsx                     # App entry point
```

## Fragment Pattern

Fragments define reusable field selections and compose via template literals:

```typescript
// src/api/fragments.ts
import gql from 'graphql-tag';

// Leaf fragment
export const Room = gql`
fragment Room on Room {
  id
  label
  applicationId
  floorId
  createdAt
  hourCodeId
  height
  notes
  description
  isOutdoor
}`;

// Composed fragment — includes child fragments
export const Floor = gql`
fragment Floor on Floor {
  id
  label
  applicationId
  height
  createdAt
  rooms {
    ...Room
  }
}${Room}`;

// Deep composition
export const Application = gql`
fragment Application on Application {
  id
  programId
  energyCompanyId
  customerId
  applicationId
  facility { ...Facility }
  customer { ...Customer }
  scopes { ...Scope }
  floors { ...Floor }
  existingConditions { ...ExistingCondition }
  controlPoints { ...ControlPoint }
  auditDetails { ...ApplicationAuditDetails }
}${Facility}${Customer}${Scope}${Floor}${ExistingCondition}${ControlPoint}${ApplicationAuditDetails}`;
```

## Query Pattern

```typescript
// src/api/queries.ts
import gql from 'graphql-tag';
import { Application, UserProgramState, Program } from './';

// Single entity by ID
export const QueryGetApplication = gql`
query GetApplication($id: ID!) {
  getApplication(id: $id) {
    ...Application
  }
}${Application}`;

// List entities
export const QueryGetAvailablePrograms = gql`
query QueryGetAvailablePrograms {
  getAvailablePrograms {
    ...Program
  }
}${Program}`;

// Multiple queries in single request
export const QueryGetProspectorConfigs = gql`
  query GetProspectorConfigs($rootId: ID!, $programId: ID!, $permissions: [PermissionRequestInput!]!) {
    getRootConfigset: getConfigSetForContainer(containerId: $rootId)
    getProgramConfigset: getConfigSetForContainer(containerId: $programId)
    getAvailableEnergyCompanies(programId: $programId)
    getAuthorizations(permissions: $permissions, programId: $programId)
  }
`;
```

## Mutation Pattern

```typescript
// src/api/mutations.ts
import gql from 'graphql-tag';
import { ApplicationAuditDetails, Scope } from './';

// Typed variables, returns fragment
export const MutationUpdateApplicationAuditDetails = gql`
    mutation UpdateApplicationAuditDetails(
        $id: ID!
        $applicationId: ID!
        $businessTypeId: String!
        $operationHourCodeId: String!
        $laborTypeId: String
        $effectiveDate: String!
    ){
        updateApplicationAuditDetails(
            id: $id
            applicationId: $applicationId
            businessTypeId: $businessTypeId
            operationHourCodeId: $operationHourCodeId
            laborTypeId: $laborTypeId
            effectiveDate: $effectiveDate
        ){
            ...ApplicationAuditDetails
        }
    }${ApplicationAuditDetails}
`;
```

## Subscription Pattern

```typescript
// src/api/subscriptions.ts
import gql from 'graphql-tag';
import { Application, ApplicationAuditDetails, Room, Floor } from './';

// Filtered by entity ID
export const SubscriptionApplicationUpdated = gql`
subscription ApplicationUpdatedSub($id: ID) {
    onUpdateApplication(id: $id) {
        ...Application
    }
}${Application}`;

// Filtered by parent ID (for child entity updates)
export const SubscriptionRoomPut = gql`
    subscription RoomPut($applicationId: ID!) {
        onPutRoom(applicationId: $applicationId) {
            ...Room
        }
    }${Room}
`;
```

## Apollo Cache Model Pattern

The `models.ts` file defines how Apollo normalizes and relates cached entities:

```typescript
// src/data/models.ts
import { CacheHandler, getModel, Model } from '@lime-energy/react-pwa/dist';
import { Application, Scope, Floor, Room, ... } from '../api';

export const MODELS: Record<string, Model> = {
  // Root entity — full form with all relationships
  application: {
    fragment: Application,
    fragmentName: 'Application',
    idName: 'applicationId',
    childLists: ['scope', 'floor', 'existingCondition', 'controlPoint'],
    childObjects: ['facility', 'customer', 'auditDetails'],
    siblings: []
  },

  // Child entity — references parent
  scope: {
    fragment: Scope,
    fragmentName: 'Scope',
    idName: 'scopeId',
    listName: 'scopes',          // key in parent's childLists
    parent: 'application',
    childLists: ['conditionInstance'],
    childObjects: [],
    siblings: []
  },

  // Grandchild — uses getModel() shorthand
  room: getModel({
    fragment: Room,
    fragmentName: 'Room',
    idName: 'roomId',
    listName: 'rooms',
    parent: 'floor',
  }),

  // Entity with cross-references (siblings)
  floor: {
    fragment: Floor,
    fragmentName: 'Floor',
    idName: 'floorId',
    listName: 'floors',
    parent: 'application',
    childLists: ['room'],
    childObjects: [],
    siblings: ['conditionInstance']   // related but not child
  },
};

export const cacheHandler = new CacheHandler(MODELS);
```

### Model Properties

| Property | Type | Purpose |
|----------|------|---------|
| `fragment` | gql | GraphQL fragment for cache reads/writes |
| `fragmentName` | string | Fragment name for Apollo cache key |
| `idName` | string | Field used as cache key suffix |
| `parent` | string | Model key of parent entity |
| `listName` | string | Key in parent's childLists where this entity appears |
| `childLists` | string[] | Model keys of child arrays |
| `childObjects` | string[] | Model keys of child objects (1:1) |
| `siblings` | string[] | Model keys of related entities (not parent/child) |
| `objectName` | string | Key in parent's childObjects (for 1:1 relationships) |

## Repository Pattern

```typescript
// src/repository.ts
import { callMutation } from '@lime-energy/react-pwa/dist';
import { MODELS, cacheHandler } from './data/models';

class Repository {
  // Simple mutation — callMutation handles cache
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

  // Complex mutation — custom optimistic response + cache update
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
        // Find or create in parent's list
        let index = applicationData.scopes.findIndex(s => s.id === scope.id);
        const newData = { ...scope, __typename: 'Scope' };

        if (index === -1) {
          applicationData.scopes.push(newData);
        } else {
          applicationData.scopes[index] = newData;
        }

        // Write both child and parent fragments
        client.writeFragment({
          id: `Scope:${scope.id}`,
          fragment: Scope,
          fragmentName: 'Scope',
          data: newData
        });
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

## Context Provider Pattern (Prospector)

```typescript
// src/context/opensearch-provider.tsx
interface OpensearchContextType {
  applications: OpenSearchApplication[];
  buckets?: Aggregations;
  getOpenSearchApplications: (props: GetProps) => void;
  loading: boolean;
  total: number;
  autocompleteValue: AutocompleteOption[];
  activeOpenSearchApplication?: OpenSearchApplication;
}

export const OpensearchContext = React.createContext<OpensearchContextType>({
  applications: [],
  getOpenSearchApplications: () => null,
  loading: true,
  // ... defaults for all fields
});

export const OpenSearchProvider: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  const [applications, setApplications] = React.useState([]);
  const [loading, setLoading] = React.useState(false);

  // Consume other contexts
  const { userState } = React.useContext(UserStateContext);
  const { activeProgram } = React.useContext(ProgramContext);

  const getOpenSearchApplications = React.useCallback((props) => {
    setLoading(true);
    getApplications({ ...props, program: activeProgram })
      .then((data) => {
        setApplications(data.results);
        setLoading(false);
      });
  }, [activeProgram]);

  return (
    <OpensearchContext.Provider value={{
      applications, loading, getOpenSearchApplications, ...
    }}>
      {children}
    </OpensearchContext.Provider>
  );
};
```

## Craco Build Configuration

```javascript
// craco.config.js
const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: (webpackConfig) => {
      // Handle CJS/ESM interop
      webpackConfig.module.rules.push({
        test: /runtimeConfig\.browser\.js$/,
        use: [{ loader: 'babel-loader', options: {
          plugins: ['@babel/plugin-transform-modules-commonjs']
        }}]
      });

      // Resolve .cjs and .ts extensions
      webpackConfig.resolve.extensions.push('.cjs', '.ts', '.tsx');

      // Node.js polyfills for browser
      webpackConfig.resolve.fallback = {
        crypto: require.resolve('crypto-browserify'),
        stream: require.resolve('stream-browserify'),
        buffer: require.resolve('buffer/'),
        util: require.resolve('util/'),
        http: require.resolve('stream-http'),
        https: require.resolve('https-browserify'),
        os: require.resolve('os-browserify/browser'),
        url: require.resolve('url/'),
        process: require.resolve('process/browser'),
        fs: false, child_process: false, path: false, http2: false, vm: false
      };

      webpackConfig.plugins.push(
        new webpack.ProvidePlugin({
          process: 'process/browser',
          Buffer: ['buffer', 'Buffer']
        })
      );

      return webpackConfig;
    }
  }
};
```

## Environment Variables

Frontend uses `REACT_APP_*` prefix (injected at build time, substituted at deploy):

```bash
# .env (local development)
REACT_APP_APPSYNC_ENDPOINT=__APPSYNC_ENDPOINT__
REACT_APP_USERPOOL_ID=__USERPOOL_ID__
REACT_APP_USERPOOL_CLIENT_ID=__USERPOOL_CLIENT_ID__
REACT_APP_COGNITO_IDENTITY_POOL_ID=__COGNITO_IDENTITY_POOL_ID__
REACT_APP_USERPOOL_REGION=__USERPOOL_REGION__
REACT_APP_OAUTH_DOMAIN=__OAUTH_DOMAIN__
REACT_APP_OAUTH_REDIRECT_SIGNIN=__OAUTH_REDIRECT_SIGNIN__
REACT_APP_OAUTH_REDIRECT_SIGNOUT=__OAUTH_REDIRECT_SIGNOUT__
```

The `__VARIABLE__` placeholders are replaced by the CloudFormation DeploymentResource at deploy time with actual values from the stack outputs.
