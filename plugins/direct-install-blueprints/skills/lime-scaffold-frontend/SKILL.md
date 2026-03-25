---
name: lime-scaffold-frontend
description: "Scaffold React frontend components, GraphQL API files, Apollo cache model, and repository methods for a Lime Energy feature. Use when building new UI features that need the full frontend stack."
---

# Scaffold Frontend Feature

Generate the frontend layer for a new feature: React components, GraphQL API files, cache model entry, and repository mutation wrappers.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/frontend-patterns.md` — Component patterns, fragments, cache models, repository
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — File naming, GraphQL naming, API file conventions

## Inputs

- **Feature name** (kebab-case, e.g., `inspection-detail`)
- **Entity name** (PascalCase, e.g., `Inspection`)
- **Entity fields** — list of fields and types
- **Parent entity** (e.g., `Application`)
- **Child entities** (optional)
- **Shared component?** — `root` (feature) or `common` (shared)

## What Gets Created

### 1. Component (`src/components/root/<feature>/`)

- Main component file (kebab-case `.tsx`)
- Sub-components as needed
- Form components using Formik + Yup for validation
- MUI components for layout and styling

### 2. Fragment (`src/api/fragments.ts`)

```typescript
export const Inspection = gql`
fragment Inspection on Inspection {
  id
  applicationId
  status
  notes
  createdAt
}`;
```

Parent fragment updated to include child via template literal:
```typescript
export const Application = gql`
fragment Application on Application {
  // ... existing fields
  inspections { ...Inspection }
}${Inspection}`;  // compose child fragment
```

### 3. Queries (`src/api/queries.ts`)

```typescript
export const QueryGetInspection = gql`
query GetInspection($id: ID!) {
  getInspection(id: $id) { ...Inspection }
}${Inspection}`;

export const QueryListInspections = gql`
query ListInspections($applicationId: ID!) {
  listInspections(applicationId: $applicationId) { ...Inspection }
}${Inspection}`;
```

### 4. Mutations (`src/api/mutations.ts`)

```typescript
export const MutationUpdateInspection = gql`
mutation UpdateInspection($id: ID!, $applicationId: ID!, $status: String, $notes: String) {
  updateInspection(id: $id, applicationId: $applicationId, status: $status, notes: $notes) {
    ...Inspection
  }
}${Inspection}`;
```

### 5. Subscriptions (`src/api/subscriptions.ts`)

```typescript
export const SubscriptionInspectionUpdated = gql`
subscription InspectionUpdated($applicationId: ID!) {
  onUpdateInspection(applicationId: $applicationId) { ...Inspection }
}${Inspection}`;
```

### 6. Cache Model (`src/data/models.ts`)

```typescript
inspection: {
  fragment: Inspection,
  fragmentName: 'Inspection',
  idName: 'id',
  listName: 'inspections',
  parent: 'application',
  childLists: [],
  childObjects: [],
  siblings: []
},
```

### 7. Repository (`src/repository.ts`)

```typescript
updateInspection(inspection, client) {
  return callMutation({
    document: MutationUpdateInspection,
    model: MODELS.inspection,
    dataName: 'updateInspection',
    mutationType: 'update',
    variables: inspection,
    cacheHandler,
    client
  });
}
```

## Key Rules

- **Never use `useEffect` for data fetching** — use Apollo's `useQuery`
- **Never store server state in React state** — Apollo cache is the source of truth
- **Always include `__typename`** in optimistic responses
- **Fragment names must match the GraphQL type name**
- **Use CacheHandler** for all cache operations, not direct writes
