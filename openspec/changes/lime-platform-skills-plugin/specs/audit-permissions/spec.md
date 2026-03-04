## ADDED Requirements

### Requirement: Map Lambda functions to IAM roles
The skill SHALL produce a mapping of every Lambda function to its IAM role and the specific permissions granted.

#### Scenario: Permission map generated
- **WHEN** user invokes `lime-audit-permissions`
- **THEN** the skill outputs a table showing each Lambda function, its role, and the actions/resources permitted

### Requirement: Identify over-permissioned roles
The skill SHALL flag IAM roles that use wildcard resources (`*`) or overly broad action sets.

#### Scenario: Wildcard resource flagged
- **WHEN** a role grants `dynamodb:*` on resource `*`
- **THEN** the skill flags it and recommends restricting to specific table ARNs and specific actions

#### Scenario: Unused permissions flagged
- **WHEN** a role grants permissions for a DynamoDB table that the function's code does not reference
- **THEN** the skill flags the potentially unused permission

### Requirement: Validate Cognito configuration
The skill SHALL check Cognito User Pool Client settings, Identity Pool role mappings, and OAuth configuration for security issues.

#### Scenario: OAuth redirect validation
- **WHEN** the Cognito User Pool Client has callback URLs
- **THEN** the skill verifies they use HTTPS (except for localhost dev URLs and app scheme deep links)

#### Scenario: Token validity check
- **WHEN** refresh token validity is set
- **THEN** the skill flags if it exceeds 30 days (the established convention)

### Requirement: Check AppSync authorization configuration
The skill SHALL verify that AppSync API authorization settings match the established pattern (Cognito primary, IAM secondary).

#### Scenario: Auth mode verified
- **WHEN** the AppSync API is checked
- **THEN** the skill confirms AMAZON_COGNITO_USER_POOLS is the default auth mode and AWS_IAM is the additional auth provider

### Requirement: Generate least-privilege recommendations
The skill SHALL output specific IAM policy recommendations that reduce each role to minimum required permissions.

#### Scenario: Recommendations generated
- **WHEN** over-permissions are found
- **THEN** the skill outputs replacement IAM policy statements with specific actions and resource ARNs
