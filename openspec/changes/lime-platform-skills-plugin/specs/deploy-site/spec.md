## ADDED Requirements

### Requirement: Orchestrate full deployment pipeline
The skill SHALL guide the user through or execute the complete deployment sequence: preprocess, build, package, deploy, upload frontend, invalidate cache.

#### Scenario: Full deployment
- **WHEN** user invokes `lime-deploy-site` with environment "dev"
- **THEN** the skill executes: (1) cfn-include to preprocess templates, (2) npm run build-local for backend, (3) npm run build for frontend, (4) sam package, (5) sam deploy with environment-specific parameters, (6) aws s3 sync for frontend, (7) CloudFront invalidation

#### Scenario: Backend-only deployment
- **WHEN** user specifies `--backend-only`
- **THEN** the skill skips frontend build, S3 sync, and CloudFront invalidation

#### Scenario: Frontend-only deployment
- **WHEN** user specifies `--frontend-only`
- **THEN** the skill skips SAM package/deploy and only builds frontend, syncs to S3, and invalidates CloudFront

### Requirement: Environment-specific parameter resolution
The skill SHALL resolve deployment parameters based on the target environment (dev, test, prod) including AWS account, region, UserPoolId, domain names, and secret names.

#### Scenario: Dev environment parameters
- **WHEN** deploying to dev
- **THEN** the skill uses dev-specific parameter overrides matching the Makefile pattern

#### Scenario: Production safeguards
- **WHEN** deploying to prod
- **THEN** the skill requires explicit confirmation, verifies the git tag exists, and checks that CI has passed

### Requirement: Provide deployment scripts
The skill SHALL include shell scripts in its `scripts/` directory that wrap the multi-step deployment process.

#### Scenario: Script available
- **WHEN** the skill is installed
- **THEN** a `deploy.sh` script is available that accepts environment, app name, and optional flags as arguments
