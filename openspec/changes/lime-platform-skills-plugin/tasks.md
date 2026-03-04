## 1. Shared References Setup

- [ ] 1.1 Create `skills/_lime-references/` directory with shared reference documents
- [ ] 1.2 Write `architecture.md` reference: event flow diagrams, service integration map, multi-tenancy model, auth flow
- [ ] 1.3 Write `conventions.md` reference: GraphQL naming, file naming, CloudFormation patterns, frontend/backend organization
- [ ] 1.4 Write `cloudformation-patterns.md` reference: SAM template structure, nested stack pattern, DynamoDB table template, AppSync config template
- [ ] 1.5 Write `vtl-templates.md` reference: canonical VTL resolver patterns for GetItem, Query, PutItem, UpdateItem, DeleteItem, field resolvers
- [ ] 1.6 Write `frontend-patterns.md` reference: Apollo cache model pattern, repository pattern, fragment structure, API file templates
- [ ] 1.7 Write `lambda-patterns.md` reference: router pattern, controller pattern, common library usage, RxJS pipeline templates

## 2. Reference Skills

- [ ] 2.1 Create `skills/lime-conventions/SKILL.md` — naming patterns, code organization, and conventions reference (references `_lime-references/conventions.md`)
- [ ] 2.2 Create `skills/lime-architecture/SKILL.md` — system design, event flows, service map, auth, and multi-tenancy reference (references `_lime-references/architecture.md`)

## 3. Core Scaffolding Skills — Resolvers & Types

- [ ] 3.1 Create `skills/lime-scaffold-resolver/SKILL.md` — VTL resolver pair generation with datasource and SAM template updates
- [ ] 3.2 Create `skills/lime-scaffold-resolver/references/` — VTL template examples for each operation type (get, list, put, update, delete, field)
- [ ] 3.3 Create `skills/lime-add-graphql-type/SKILL.md` — full entity lifecycle: schema + resolvers + frontend API + cache model
- [ ] 3.4 Create `skills/lime-add-graphql-type/references/` — example schema type, full resolver set, frontend API file snippets

## 4. Infrastructure Skills — DynamoDB & Lambda

- [ ] 4.1 Create `skills/lime-add-dynamo-table/SKILL.md` — add table to nested stack with GSIs, streams, datasource, IAM
- [ ] 4.2 Create `skills/lime-add-dynamo-table/references/` — DynamoDB template snippet, AppSync datasource snippet, IAM role snippet
- [ ] 4.3 Create `skills/lime-scaffold-lambda/SKILL.md` — Lambda function with router, controllers, IAM, event source
- [ ] 4.4 Create `skills/lime-scaffold-lambda/references/` — handler template, controller template, SAM function resource snippet
- [ ] 4.5 Create `skills/lime-add-lambda-trigger/SKILL.md` — wire DDB stream to Lambda with controller and router registration
- [ ] 4.6 Create `skills/lime-add-lambda-trigger/references/` — EventSourceMapping snippet, controller templates for AppSync/SDS/OpenSearch targets

## 5. Frontend Scaffolding Skill

- [ ] 5.1 Create `skills/lime-scaffold-frontend/SKILL.md` — component tree, GraphQL API files, cache model, repository wrapper
- [ ] 5.2 Create `skills/lime-scaffold-frontend/references/` — component template, API file templates, models.ts entry template, repository method template

## 6. CloudFormation Management Skills

- [ ] 6.1 Create `skills/lime-update-cfn-stack/SKILL.md` — safe nested stack edits with breaking change detection and reference integrity
- [ ] 6.2 Create `skills/lime-scaffold-site/SKILL.md` — full monorepo generation from template
- [ ] 6.3 Create `skills/lime-scaffold-site/references/` — complete SAM template skeleton, nested stack templates, schema skeleton, workflow files, package.json templates, craco.config.js

## 7. Operations Skills

- [ ] 7.1 Create `skills/lime-deploy-site/SKILL.md` — deployment orchestration with environment-specific parameters
- [ ] 7.2 Create `skills/lime-deploy-site/scripts/deploy.sh` — shell script wrapping the multi-step deploy flow
- [ ] 7.3 Create `skills/lime-diagnose-lambda/SKILL.md` — CloudWatch log queries, stream tracing, failure pattern detection
- [ ] 7.4 Create `skills/lime-diagnose-lambda/scripts/` — logs.sh, stream-health.sh, invocations.sh diagnostic scripts
- [ ] 7.5 Create `skills/lime-validate-stack/SKILL.md` — CFN lint, resolver-schema consistency, IAM completeness, reference integrity
- [ ] 7.6 Create `skills/lime-validate-stack/scripts/validate.sh` — validation runner script
- [ ] 7.7 Create `skills/lime-audit-permissions/SKILL.md` — IAM role mapping, over-permission detection, Cognito validation, recommendations
- [ ] 7.8 Create `skills/lime-review-pr/SKILL.md` — domain-aware code review for cross-file consistency, conventions, subscription wiring

## 8. Verification

- [ ] 8.1 Verify all 15 skill directories exist under `skills/` with valid SKILL.md files
- [ ] 8.2 Verify `_lime-references/` contains all shared reference documents
- [ ] 8.3 Verify skills are automatically discovered by the Nix manifest wildcard (`skills = [ "*" ]`)
- [ ] 8.4 Test a scaffolding skill (lime-scaffold-resolver) against the actual Auditor repo to verify output correctness
