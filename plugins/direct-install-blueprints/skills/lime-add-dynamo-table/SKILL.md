---
name: lime-add-dynamo-table
description: "Add a DynamoDB table to a Lime Energy app's nested stack with GSIs, streams, AppSync datasource, and IAM permissions. Use when creating new data storage for an entity."
---

# Add DynamoDB Table

Add a new DynamoDB table to the nested stack with all required configuration: GSIs, streams, outputs, AppSync datasource, and IAM role updates.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — DynamoDB nested stack pattern, IAM roles
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Table naming, CloudFormation conventions

## Inputs

- **Table name** (PascalCase, e.g., `InspectionsTable`)
- **Hash key** (default: `id` type `S`)
- **Sort key** (optional, e.g., `dateCreated` type `S`)
- **GSIs** (e.g., `applicationId`, `programId`, `energyCompanyId`)

## What Gets Created

### 1. Table in `backend/dynamodb-template.yml`

```yaml
InspectionsTable:
  Type: AWS::DynamoDB::Table
  Properties:
    BillingMode: PAY_PER_REQUEST
    StreamSpecification:
      StreamViewType: NEW_AND_OLD_IMAGES
    KeySchema:
      - AttributeName: id
        KeyType: HASH
    AttributeDefinitions:
      - AttributeName: id
        AttributeType: S
      - AttributeName: applicationId
        AttributeType: S
    GlobalSecondaryIndexes:
      - IndexName: applicationId-index
        KeySchema:
          - AttributeName: applicationId
            KeyType: HASH
        Projection:
          ProjectionType: ALL
```

Every table MUST have:
- `BillingMode: PAY_PER_REQUEST`
- `StreamSpecification: NEW_AND_OLD_IMAGES`
- GSI Projection: `ALL`

### 2. Outputs in `backend/dynamodb-template.yml`

```yaml
Outputs:
  InspectionsTableName:
    Value: !Ref InspectionsTable
  InspectionsTableArn:
    Value: !GetAtt InspectionsTable.Arn
  InspectionsTableStreamArn:
    Value: !GetAtt InspectionsTable.StreamArn
```

### 3. IAM Role Update in `backend/dynamodb-template.yml`

Add the new table ARN and index ARNs to the DynamoDBRole policy:

```yaml
- !GetAtt InspectionsTable.Arn
- !Sub "${InspectionsTable.Arn}/index/*"
```

Actions: GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, BatchWriteItem.

### 4. AppSync DataSource in `backend/<app>.yml`

```yaml
InspectionsTableDataSource:
  Type: AWS::AppSync::DataSource
  Properties:
    ApiId: !GetAtt AppSyncApi.ApiId
    Name: InspectionsTable
    Type: AMAZON_DYNAMODB
    DynamoDBConfig:
      AwsRegion: !Ref AWS::Region
      TableName: !GetAtt DynamoDB.Outputs.InspectionsTableName
    ServiceRoleArn: !GetAtt DynamoDB.Outputs.DynamoDBRoleArn
```

## Checklist

- [ ] Table added to `dynamodb-template.yml` with PAY_PER_REQUEST + streams
- [ ] All GSIs have `Projection: ALL`
- [ ] AttributeDefinitions includes all key attributes (primary + GSI keys)
- [ ] Outputs added for TableName, TableArn, TableStreamArn
- [ ] DynamoDBRole policy updated with table ARN + index ARN
- [ ] AppSync DataSource added in main SAM template
- [ ] DataSource references nested stack output for table name
