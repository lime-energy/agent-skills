# CloudFormation / SAM Patterns

Last verified: 2026-03-04

## Monorepo Template Structure

```
backend/
├── <app-name>.yml           # Main SAM template (1,300-1,700 lines)
├── dynamodb-template.yml    # Nested stack: all DynamoDB tables
├── cognito-template.yml     # Nested stack: Identity Pool, User Pool Client
├── schema.graphql           # AppSync GraphQL schema (600-750 lines)
├── resolvers/               # VTL request/response pairs (60+ per app)
├── src/                     # Lambda function source (TypeScript)
│   ├── common/              # Shared library
│   └── <function-name>/     # Per-function directories
├── dist/                    # Built Lambda code (esbuild output)
├── dependencies/            # Lambda Layer dependencies
├── package.json             # Backend dependencies
└── tsconfig.json            # TypeScript config
```

## Main SAM Template Pattern

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform:
- AWS::Serverless-2016-10-31

Parameters:
  # -- Required across all apps --
  ApiName:
    Type: String
  AppStage:
    Type: String
  StackEnv:
    Type: String
    Default: dev
  DomainName:
    Type: String
  FullDomainName:
    Type: String
  AcmCertificateArn:
    Type: String
  UserPoolId:
    Type: String
  UserPoolDomain:
    Type: String
  IdentityProvider:
    Type: String
  UserPoolProviderName:
    Type: String
  AppScheme:
    Type: String
  EnableLocalUserPoolClients:
    AllowedValues: ['Yes', 'No']
    Default: 'No'
    Type: String
  BuildLocally:
    AllowedValues: ['Yes', 'No']
    Default: 'No'
    Type: String
  # -- SDS streams (event bus) --
  SDSLowPriorityStreamArn:
    Type: String
  SDSNormalPriorityStreamArn:
    Type: String
  SDSLowPriorityStreamName:
    Type: String
  SDSNormalPriorityStreamName:
    Type: String
  # -- WebACL/WAF --
  GlobalSiteWebACLArn:
    Type: String
    Default: ""
  RegionalApiWebAclArn:
    Type: String
    Default: ""

Conditions:
  LocalUserPoolClientsEnabled: !Equals [!Ref EnableLocalUserPoolClients, 'Yes']
  BuildModuleLayer: !Equals [!Ref BuildLocally, 'No']

Resources:
  # -- Nested Stacks --
  DynamoDB:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: ./dynamodb-template.yml

  Cognito:
    Type: AWS::CloudFormation::Stack
    Properties:
      Parameters:
        ApiName: !Ref ApiName
        FullDomainName: !Ref FullDomainName
        UserPoolId: !Ref UserPoolId
        UserPoolProviderName: !Ref UserPoolProviderName
        AppScheme: !Ref AppScheme
        EnableLocalUserPoolClients: !Ref EnableLocalUserPoolClients
        IdentityProvider: !Ref IdentityProvider
      TemplateURL: ./cognito-template.yml

  # -- External SAM Apps --
  Configurator:
    Type: AWS::Serverless::Application
    Properties:
      Location: <S3 URL to configurator SAM template>
      Parameters:
        AppSyncApi: !Ref AppSyncApi
        ApiUrl: !GetAtt AppSyncApi.GraphQLUrl
        ApiId: !GetAtt AppSyncApi.ApiId
        StackEnv: !Ref StackEnv
        # ... additional params

  # -- AppSync API (see below) --
  # -- Lambda Functions (see below) --
  # -- S3 + CloudFront (see below) --
```

## AppSync API Pattern

```yaml
  AppSyncApi:
    Type: "AWS::AppSync::GraphQLApi"
    Properties:
      UserPoolConfig:
        UserPoolId: !Ref UserPoolId
        AwsRegion: !Sub ${AWS::Region}
        DefaultAction: ALLOW
      Name: !Ref ApiName
      IntrospectionConfig: DISABLED
      AuthenticationType: AMAZON_COGNITO_USER_POOLS
      AdditionalAuthenticationProviders:
        - AuthenticationType: AWS_IAM
      LogConfig:
        CloudWatchLogsRoleArn: !GetAtt LoggingRole.Arn
        FieldLogLevel: ERROR

  AppSyncSchema:
    Type: "AWS::AppSync::GraphQLSchema"
    Properties:
      DefinitionS3Location: ./schema.graphql
      ApiId: !GetAtt AppSyncApi.ApiId
```

### AppSync DataSource (DynamoDB)

```yaml
  ApplicationsDataSource:
    Type: "AWS::AppSync::DataSource"
    Properties:
      ApiId: !GetAtt AppSyncApi.ApiId
      Name: ApplicationsTable
      Type: AMAZON_DYNAMODB
      ServiceRoleArn: !GetAtt DynamoDB.Outputs.DynamoDBRoleArn
      DynamoDBConfig:
        TableName: !GetAtt DynamoDB.Outputs.ApplicationsTableName
        AwsRegion: !Sub ${AWS::Region}
```

### AppSync Resolver

```yaml
  GetApplicationResolver:
    Type: "AWS::AppSync::Resolver"
    DependsOn: AppSyncSchema
    Properties:
      ApiId: !GetAtt AppSyncApi.ApiId
      TypeName: Query
      FieldName: getApplication
      DataSourceName: !GetAtt ApplicationsDataSource.Name
      RequestMappingTemplateS3Location: ./resolvers/Query-getApplication.request
      ResponseMappingTemplateS3Location: ./resolvers/Query-getApplication.response
```

## DynamoDB Nested Stack Pattern

```yaml
# dynamodb-template.yml
AWSTemplateFormatVersion: "2010-09-09"

Outputs:
  DynamoDBRoleArn:
    Value: !GetAtt DynamoDBRole.Arn
  # For each table, export: Name, Arn, StreamArn (if streams enabled)
  ApplicationsTableName:
    Value: !Ref ApplicationsTable
  ApplicationsTableArn:
    Value: !GetAtt ApplicationsTable.Arn
  ApplicationsTableStreamArn:
    Value: !GetAtt ApplicationsTable.StreamArn

Resources:
  # -- IAM Role for AppSync --
  DynamoDBRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Action: sts:AssumeRole
            Principal:
              Service: appsync.amazonaws.com
      Policies:
        - PolicyName: "AppSyncDynamoDBPolicy"
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
            - Effect: Allow
              Action:
              - dynamodb:GetItem
              - dynamodb:PutItem
              - dynamodb:DeleteItem
              - dynamodb:UpdateItem
              - dynamodb:Query
              - dynamodb:Scan
              - dynamodb:BatchGetItem
              - dynamodb:BatchWriteItem
              Resource:
                # For each table: ARN + ARN/* (for GSI access)
                - !Join ["", [!GetAtt ApplicationsTable.Arn, "*"]]
                - !GetAtt ApplicationsTable.Arn

  # -- Table: standard pattern --
  ApplicationsTable:
    Type: "AWS::DynamoDB::Table"
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: "id"
          AttributeType: "S"
        - AttributeName: "programId"
          AttributeType: "S"
        - AttributeName: "energyCompanyId"
          AttributeType: "S"
      KeySchema:
        - AttributeName: "id"
          KeyType: "HASH"
      GlobalSecondaryIndexes:
        - IndexName: programId-index
          KeySchema:
            - AttributeName: "programId"
              KeyType: "HASH"
          Projection:
            ProjectionType: ALL
        - IndexName: energyCompanyId-index
          KeySchema:
            - AttributeName: "energyCompanyId"
              KeyType: "HASH"
          Projection:
            ProjectionType: ALL
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES

  # -- Table: simple (no GSI, no stream) --
  CustomersTable:
    Type: "AWS::DynamoDB::Table"
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: "id"
          AttributeType: "S"
      KeySchema:
        - AttributeName: "id"
          KeyType: "HASH"

  # -- Table: composite key (rare, only ESignFileTable in Closer) --
  ESignFileTable:
    Type: "AWS::DynamoDB::Table"
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: "id"
          AttributeType: "S"
        - AttributeName: "dateCreated"
          AttributeType: "S"
      KeySchema:
        - AttributeName: "id"
          KeyType: "HASH"
        - AttributeName: "dateCreated"
          KeyType: "RANGE"
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
```

### DynamoDB Table Conventions

- **BillingMode**: Always `PAY_PER_REQUEST`
- **Primary Key**: Always `id` (S) as HASH (except ApplicationAuditDetailsTable which uses `applicationId`)
- **Streams**: `NEW_AND_OLD_IMAGES` on all tables that trigger Lambda processing
- **GSI Naming**: `<attribute>-index` (e.g., `programId-index`, `applicationId-index`)
- **GSI Projection**: Always `ALL`
- **Sort Keys**: Rare. Only ESignFileTable uses `dateCreated` as RANGE key

## S3 + CloudFront Pattern

```yaml
  OriginAccessIdentity:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: !Sub "${FullDomainName} OAI"

  WebsiteBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref FullDomainName
      WebsiteConfiguration:
        IndexDocument: index.html
        ErrorDocument: index.html
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  WebsiteBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref WebsiteBucket
      PolicyDocument:
        Statement:
        - Action: "s3:Get*"
          Effect: Allow
          Resource: !Join ['', ['arn:aws:s3:::', !Ref WebsiteBucket, /*]]
          Principal:
            CanonicalUser: !GetAtt OriginAccessIdentity.S3CanonicalUserId

  WebsiteCloudfront:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
          - DomainName: !GetAtt WebsiteBucket.DomainName
            Id: S3Origin
            S3OriginConfig:
              OriginAccessIdentity: !Join ["", ["origin-access-identity/cloudfront/", !Ref OriginAccessIdentity]]
        Enabled: true
        HttpVersion: 'http2'
        DefaultRootObject: index.html
        Aliases:
          - !Ref FullDomainName
        DefaultCacheBehavior:
          AllowedMethods: [GET, HEAD]
          Compress: true
          TargetOriginId: S3Origin
          ForwardedValues:
            QueryString: true
            Cookies:
              Forward: none
          ViewerProtocolPolicy: redirect-to-https
        ViewerCertificate:
          AcmCertificateArn: !Ref AcmCertificateArn
          SslSupportMethod: sni-only
          MinimumProtocolVersion: TLSv1.2_2021
        # SPA routing: return index.html for 403/404
        CustomErrorResponses:
          - ErrorCachingMinTTL: 30
            ErrorCode: 403
            ResponseCode: 200
            ResponsePagePath: '/index.html'
          - ErrorCachingMinTTL: 30
            ErrorCode: 404
            ResponseCode: 200
            ResponsePagePath: '/index.html'
```

## Frontend Config Substitution

The deployment resource replaces `__VARIABLE__` placeholders in built frontend files:

```yaml
  DeploymentResource:
    Type: AWS::CloudFormation::CustomResource
    Properties:
      Substitutions:
        FilePattern: "**/*.html,**/*.js,**/*.json"
        Values:
          "__APPSYNC_ENDPOINT__": !GetAtt AppSyncApi.GraphQLUrl
          "__USERPOOL_ID__": !Ref UserPoolId
          "__USERPOOL_CLIENT_ID__": !GetAtt Cognito.Outputs.UserPoolClientId
          "__COGNITO_IDENTITY_POOL_ID__": !GetAtt Cognito.Outputs.IdentityPoolId
          "__OAUTH_DOMAIN__": !Ref UserPoolDomain
          "__OAUTH_REDIRECT_SIGNIN__": !Sub https://${FullDomainName}/
          "__OAUTH_REDIRECT_SIGNOUT__": !Sub https://${FullDomainName}/
```

These map to `REACT_APP_*` environment variables in `.env` files for local development.

## Cognito Nested Stack Pattern

See the full `cognito-template.yml` in the Auditor repo. Key resources:

- `IdentityPool` — links User Pool to Identity Pool
- `UserPoolClient` — OAuth 2.0 code flow, scopes: phone/email/openid/profile/signin.user.admin
- `AuthorizedRole` / `UnAuthorizedRole` — IAM roles for authenticated/unauthenticated users
- `IdentityPoolRoleMapping` — maps roles to Identity Pool
- Conditional `Local*` variants for dev (localhost:3000 callback URLs)
- RefreshTokenValidity: 30 days
