## ADDED Requirements

### Requirement: Generate React component tree
The skill SHALL create components following the established `src/components/root/` and `src/components/common/` pattern with TypeScript and MUI.

#### Scenario: Feature component scaffolded
- **WHEN** user invokes `lime-scaffold-frontend` with feature name "inspection-detail"
- **THEN** the skill creates `src/components/root/inspection-detail/` with a main component file, supporting sub-components, and form components using Formik + Yup

#### Scenario: Shared component scaffolded
- **WHEN** user specifies the component is shared
- **THEN** it is placed in `src/components/common/` instead of `src/components/root/`

### Requirement: Generate GraphQL API files
The skill SHALL create or update the GraphQL API layer in `src/api/` with queries, mutations, subscriptions, and fragments for the new feature.

#### Scenario: Query file updated
- **WHEN** a new entity "Inspection" is part of the feature
- **THEN** `src/api/queries.ts` is updated with QueryGetInspection and QueryListInspections using the entity fragment

#### Scenario: Mutation file updated
- **WHEN** the entity supports CRUD
- **THEN** `src/api/mutations.ts` is updated with MutationUpdateInspection, MutationPutInspection, and MutationDeleteInspection

#### Scenario: Subscription file updated
- **WHEN** the entity needs real-time updates
- **THEN** `src/api/subscriptions.ts` is updated with SubscriptionInspectionUpdated filtered by entity ID

#### Scenario: Fragment file updated
- **WHEN** the entity has fields and relationships
- **THEN** `src/api/fragments.ts` is updated with an Inspection fragment including nested child fragments

### Requirement: Configure Apollo cache model
The skill SHALL add cache model entries to `src/data/models.ts` defining the entity's parent, children, and fragment relationships for Apollo normalized cache.

#### Scenario: Cache model registered
- **WHEN** an Inspection entity belongs to an Application and has child InspectionItems
- **THEN** `src/data/models.ts` includes an entry with `parent: 'application'`, `childLists: ['inspectionItem']`, and the correct fragment reference

### Requirement: Create repository wrapper
The skill SHALL add mutation wrapper methods to `src/repository.ts` with optimistic update handling and cache invalidation logic.

#### Scenario: Repository method with optimistic updates
- **WHEN** a mutation for updateInspection is needed
- **THEN** `src/repository.ts` gets an `updateInspection(inspection, client)` method that writes an optimistic response to the Apollo cache and calls the mutation

### Requirement: Optionally generate Context provider
The skill SHALL offer to create a React Context provider in `src/context/` when the feature manages complex state beyond Apollo cache (following the Prospector pattern).

#### Scenario: Context provider created
- **WHEN** user opts for a context provider
- **THEN** the skill creates `src/context/inspection-provider.tsx` with typed context, state management via useState/useCallback, and a Provider component wrapping children
