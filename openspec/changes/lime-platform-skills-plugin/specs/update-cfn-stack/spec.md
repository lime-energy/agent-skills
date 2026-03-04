## ADDED Requirements

### Requirement: Validate changes before applying
The skill SHALL analyze proposed CloudFormation changes and identify potential breaking changes, resource replacements, or cross-stack reference issues.

#### Scenario: Breaking change detected
- **WHEN** user proposes changing a DynamoDB table's primary key
- **THEN** the skill warns that this requires table replacement and data migration, and blocks the change without explicit confirmation

#### Scenario: Safe change validated
- **WHEN** user proposes adding a new GSI to an existing table
- **THEN** the skill confirms this is a safe additive change and proceeds

### Requirement: Manage cross-stack references
The skill SHALL ensure that changes to nested stack outputs are reflected in the parent stack and vice versa.

#### Scenario: New output propagated
- **WHEN** a new table is added to dynamodb-template.yml with outputs
- **THEN** the skill verifies the parent stack references the new outputs via `!GetAtt DynamoDB.Outputs.<OutputName>` wherever needed

#### Scenario: Removed output detected
- **WHEN** a nested stack output is removed
- **THEN** the skill identifies all parent stack references to that output and flags them as requiring updates

### Requirement: Handle parameter additions
The skill SHALL add new parameters to the main SAM template and propagate them to nested stacks as needed.

#### Scenario: New secret parameter
- **WHEN** user needs to add a new external service credential
- **THEN** the skill adds a parameter with NoEcho: true, adds it to the relevant nested stack's Parameters, and creates the corresponding environment variable in the Lambda function

### Requirement: Maintain template formatting
The skill SHALL preserve the existing formatting, comment structure, and resource ordering conventions in CloudFormation templates.

#### Scenario: Consistent insertion point
- **WHEN** adding a new Lambda function resource
- **THEN** it is placed in the same section as other Lambda functions, following the same indentation and comment style
