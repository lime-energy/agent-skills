---
name: lime-add-graphql-type
description: "Add a complete GraphQL entity type to a Lime Energy app — schema, VTL resolvers, frontend API files, cache model, and SAM resources. Use when adding a new data entity that needs full CRUD across the stack."
---

# Add GraphQL Type

Add a complete entity type across the entire Lime Energy stack: GraphQL schema, VTL resolvers, SAM template resources, frontend fragments/queries/mutations/subscriptions, and Apollo cache model.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/vtl-templates.md` — VTL resolver patterns
- `${CLAUDE_PLUGIN_ROOT}/references/frontend-patterns.md` — Fragment composition, API files, cache models
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Naming conventions for all layers
- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — AppSync resolver SAM resources

## Inputs

- **Entity name** (PascalCase, e.g., `Inspection`)
- **Fields** with types (e.g., `id: ID!, applicationId: ID!, status: String, notes: String, createdAt: String`)
- **Parent entity** (e.g., `Application`)
- **Child entities** (e.g., `InspectionItem`)
- **Target table** (e.g., `InspectionsTable`)

## What Gets Created

### 1. GraphQL Schema (`backend/schema.graphql`)

- Type definition with all fields and auth directives
- Input type (`<Type>Input`)
- Query fields: `get<Type>(id: ID!): <Type>`, `list<Types>(<parentId>: ID!): [<Type>]`
- Mutation fields: `update<Type>(...)`, `put<Type>(input: <Type>Input!): <Type>`, `delete<Type>(id: ID!, <parentId>: ID!): <Type>`
- Subscription field: `on<Update|Put|Delete><Type>(<parentId>: ID): <Type>`
- Parent type gets `<children>: [<Type>]` field if relationship specified

### 2. VTL Resolvers (`backend/resolvers/`)

Complete resolver set:
- `Query-get<Type>.request/response` — GetItem by ID
- `Query-list<Types>.request/response` — Query GSI by parent ID
- `Mutation-update<Type>.request/response` — Expression-based UpdateItem
- `Mutation-put<Type>.request/response` — PutItem with auto ID + createdBy
- `Mutation-delete<Type>.request/response` — DeleteItem with condition
- `<Parent>-<children>.request/response` — Field resolver for parent→child

### 3. SAM Template (`backend/<app>.yml`)

- `AWS::AppSync::Resolver` for each resolver pair
- `AWS::AppSync::DataSource` for the target table (if not existing)

### 4. Frontend Fragment (`src/api/fragments.ts`)

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

Parent fragment updated to include child: `inspections { ...Inspection }` with `${Inspection}` template literal.

### 5. Frontend Queries (`src/api/queries.ts`)

```typescript
export const QueryGetInspection = gql`
query GetInspection($id: ID!) {
  getInspection(id: $id) { ...Inspection }
}${Inspection}`;
```

### 6. Frontend Mutations (`src/api/mutations.ts`)

```typescript
export const MutationUpdateInspection = gql`
mutation UpdateInspection($id: ID!, $applicationId: ID!, ...) {
  updateInspection(id: $id, applicationId: $applicationId, ...) { ...Inspection }
}${Inspection}`;
```

### 7. Frontend Subscriptions (`src/api/subscriptions.ts`)

```typescript
export const SubscriptionInspectionUpdated = gql`
subscription InspectionUpdated($applicationId: ID!) {
  onUpdateInspection(applicationId: $applicationId) { ...Inspection }
}${Inspection}`;
```

### 8. Cache Model (`src/data/models.ts`)

```typescript
inspection: {
  fragment: Inspection,
  fragmentName: 'Inspection',
  idName: 'id',
  listName: 'inspections',
  parent: 'application',
  childLists: ['inspectionItem'],
  childObjects: [],
  siblings: []
},
```

## After Completion

Run `npm run generate-types` to regenerate TypeScript types from the updated schema.
