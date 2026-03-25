---
name: lime-scaffold-resolver
description: "Generate VTL resolver pairs for Lime Energy AppSync APIs. Use when creating new GraphQL resolvers — GetItem, Query/GSI, PutItem, UpdateItem, DeleteItem, or field resolvers — with corresponding SAM template and schema updates."
---

# Scaffold VTL Resolver

Generate VTL request/response mapping template pairs for AppSync resolvers following Lime Energy patterns.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/vtl-templates.md` — All VTL resolver patterns with real code
- `${CLAUDE_PLUGIN_ROOT}/references/conventions.md` — Resolver file naming conventions
- `${CLAUDE_PLUGIN_ROOT}/references/cloudformation-patterns.md` — AppSync resolver SAM resources

## Inputs

- **Type name** (e.g., `Inspection`)
- **Operation** — one of: get, list, put, update, delete, field
- **Table name** — DynamoDB table the resolver targets
- **GSI name** (for list/field) — e.g., `applicationId-index`
- **Field name** (for field resolvers) — e.g., `items`

## What Gets Created

### 1. VTL Template Pair

Files in `backend/resolvers/`:

| Operation | Request File | Response File |
|-----------|-------------|--------------|
| get | `Query-get<Type>.request` | `Query-get<Type>.response` |
| list | `Query-list<Types>.request` | `Query-list<Types>.response` |
| put | `Mutation-put<Type>.request` | `Mutation-put<Type>.response` |
| update | `Mutation-update<Type>.request` | `Mutation-update<Type>.response` |
| delete | `Mutation-delete<Type>.request` | `Mutation-delete<Type>.response` |
| field | `<ParentType>-<field>.request` | `<ParentType>-<field>.response` |

### 2. SAM Template Updates

Add to `backend/<app>.yml`:

- `AWS::AppSync::Resolver` resource referencing the VTL templates
- `AWS::AppSync::DataSource` if one doesn't exist for the target table

### 3. Schema Updates

Add to `backend/schema.graphql`:

- Query/Mutation/Subscription field definitions
- Type definition if it doesn't exist
- Auth directives: `@aws_cognito_user_pools @aws_iam`

## VTL Pattern Reference

### GetItem Request
```velocity
{
  "version": "2017-02-28",
  "operation": "GetItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
  }
}
```

### Query (GSI) Request
```velocity
{
  "version": "2017-02-28",
  "operation": "Query",
  "index": "applicationId-index",
  "query": {
    "expression": "applicationId = :applicationId",
    "expressionValues": {
      ":applicationId": $util.dynamodb.toDynamoDBJson($ctx.args.applicationId)
    }
  }
}
```

### PutItem Request (with auto ID and createdBy)
```velocity
$util.qr($ctx.args.input.put("id", $util.autoId()))
$util.qr($ctx.args.input.put("createdBy", $ctx.identity.username))
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.args.input.id)
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($ctx.args.input)
}
```

### UpdateItem Request (expression-based)
```velocity
#set($expSet = [])
#set($expValues = {})
#foreach($entry in $ctx.args.entrySet())
  #if($entry.key != "id")
    $util.qr($expSet.add("#${entry.key} = :${entry.key}"))
    $util.qr($expValues.put(":${entry.key}", $util.dynamodb.toDynamoDB($entry.value)))
  #end
#end
{
  "version": "2017-02-28",
  "operation": "UpdateItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
  },
  "update": {
    "expression": "SET ${expSet.join(', ')}",
    "expressionValues": $util.toJson($expValues)
  }
}
```

### DeleteItem Request
```velocity
{
  "version": "2017-02-28",
  "operation": "DeleteItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
  },
  "condition": {
    "expression": "attribute_exists(id)"
  }
}
```

### Standard Response
```velocity
$util.toJson($ctx.result)
```

### List Response
```velocity
$util.toJson($ctx.result.items)
```

See `${CLAUDE_PLUGIN_ROOT}/references/vtl-templates.md` for the complete set of patterns including BatchGetItem and conditional updates.
