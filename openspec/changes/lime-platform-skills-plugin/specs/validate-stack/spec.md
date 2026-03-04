## ADDED Requirements

### Requirement: Lint CloudFormation templates
The skill SHALL validate all CloudFormation templates (main SAM template and nested stacks) against AWS rules and best practices.

#### Scenario: Template validation
- **WHEN** user invokes `lime-validate-stack`
- **THEN** the skill runs cfn-lint on `backend/<app>.yml`, `backend/dynamodb-template.yml`, and `backend/cognito-template.yml` and reports any errors or warnings

#### Scenario: SAM-specific validation
- **WHEN** the template uses SAM transforms
- **THEN** the skill validates SAM-specific resources (AWS::Serverless::Function, AWS::Serverless::Application) with correct properties

### Requirement: Check resolver-schema consistency
The skill SHALL verify that every resolver file in `backend/resolvers/` has a corresponding field in `backend/schema.graphql` and vice versa.

#### Scenario: Orphaned resolver detected
- **WHEN** a VTL resolver pair exists for `Query-getInspection` but schema.graphql has no `getInspection` field in the Query type
- **THEN** the skill reports the orphaned resolver and suggests either adding the schema field or removing the resolver

#### Scenario: Missing resolver detected
- **WHEN** schema.graphql has a `getInspection` field but no resolver pair exists
- **THEN** the skill reports the missing resolver and suggests creating it

### Requirement: Verify IAM role completeness
The skill SHALL check that every Lambda function's IAM role has permissions for all resources it accesses (DynamoDB tables, AppSync API, S3 buckets, etc.).

#### Scenario: Missing permission detected
- **WHEN** a Lambda function's code imports from a DynamoDB table not listed in its IAM role
- **THEN** the skill flags the missing permission

### Requirement: Check nested stack reference integrity
The skill SHALL verify that all `!GetAtt` and `!Ref` references between parent and nested stacks resolve correctly.

#### Scenario: Broken reference detected
- **WHEN** the parent stack references `!GetAtt DynamoDB.Outputs.InspectionsTableName` but the DynamoDB nested stack has no such output
- **THEN** the skill reports the broken reference

### Requirement: Validate GraphQL schema syntax
The skill SHALL check the GraphQL schema for syntax errors, duplicate type definitions, and missing type references.

#### Scenario: Schema syntax error
- **WHEN** schema.graphql has a syntax error
- **THEN** the skill reports the error with line number and suggestion
