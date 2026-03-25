---
name: lime-deploy-site
description: "Deploy a Lime Energy app to AWS — SAM package/deploy, frontend S3 sync, CloudFront invalidation. Use when deploying Auditor, Closer, or Prospector to dev, test, or production."
---

# Deploy Site

Orchestrate the full deployment pipeline for a Lime Energy application.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — SAM template structure, config substitution
- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — AWS service map, CloudFront/S3 hosting

## Deployment Sequence

### Full Deploy
```bash
# 1. Preprocess CloudFormation (resolve nested includes)
npx cfn-include backend/<app>.yml > backend/<app>-processed.yml

# 2. Build backend (TypeScript → JavaScript)
cd backend && npm run build-local && cd ..

# 3. Build frontend
npm run build

# 4. Package SAM template (upload artifacts to S3)
sam package \
  --template-file backend/<app>-processed.yml \
  --output-template-file backend/<app>-packaged.yml \
  --s3-bucket <deployment-bucket>

# 5. Deploy SAM stack
sam deploy \
  --template-file backend/<app>-packaged.yml \
  --stack-name <app>-<env> \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --parameter-overrides <env-specific-params>

# 6. Upload frontend to S3
aws s3 sync build/ s3://<frontend-bucket> --delete

# 7. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <dist-id> \
  --paths "/*"
```

### Backend Only
Skip steps 3, 6, 7.

### Frontend Only
Skip steps 1, 2, 4, 5.

## Environment Parameters

Each environment has specific parameter overrides for `sam deploy`:
- `AppStage` — dev, test, prod
- `StackEnv` — environment identifier
- `UserPoolId` — Cognito User Pool (shared)
- `FullDomainName` — app domain
- `ApiName` — AppSync API name

## Production Safeguards

Before deploying to prod:
1. Verify a git tag exists for the release
2. Confirm CI has passed on the tagged commit
3. Require explicit user confirmation
4. Check that no breaking CloudFormation changes will cause resource replacement
