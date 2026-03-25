# VTL Resolver Templates

Last verified: 2026-03-04

Canonical VTL (Velocity Template Language) patterns extracted from Auditor, Closer, and Prospector.

## File Naming Convention

```
backend/resolvers/
├── Query-get<Type>.request          # GetItem by ID
├── Query-get<Type>.response         # Return single item
├── Query-list<Types>.request        # Query by GSI
├── Query-list<Types>.response       # Return item list
├── Mutation-update<Type>.request    # UpdateItem with expressions
├── Mutation-update<Type>.response   # Return updated item
├── Mutation-put<Type>.request       # PutItem (create/replace)
├── Mutation-put<Type>.response      # Return created item
├── Mutation-delete<Type>.request    # DeleteItem
├── Mutation-delete<Type>.response   # Return deleted item
├── <Parent>-<children>.request      # Field resolver (GSI query)
├── <Parent>-<children>.response     # Return child items
└── Mutation-update<Type>Stream.request  # Stream mutation (Lambda-initiated)
```

## GetItem Resolver

### Request
```vtl
{
    "version": "2017-02-28",
    "operation": "GetItem",
    "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
    }
}
```

### Response
```vtl
$util.toJson($ctx.result)
```

## Query (GSI) Resolver — List by Index

### Request
```vtl
{
    "version" : "2017-02-28",
    "operation" : "Query",
    "query" : {
        "expression" : "programId = :programId",
        "expressionValues" : {
            ":programId" : $util.dynamodb.toDynamoDBJson($ctx.args.programId)
        }
    },
    "index" : "programId-index"
}
```

### Response
```vtl
$util.toJson($ctx.result.items)
```

## Field Resolver — Parent-Child Relationship

Uses `$ctx.source` (the parent object) instead of `$ctx.args`.

### Request (e.g., Application-scopes.request)
```vtl
{
    "version" : "2017-02-28",
    "operation" : "Query",
    "query" : {
        "expression" : "applicationId = :applicationId",
        "expressionValues" : {
            ":applicationId" : $util.dynamodb.toDynamoDBJson(${ctx.source.id})
        }
    },
    "index" : "applicationId-index"
}
```

### Response
```vtl
$util.toJson($ctx.result.items)
```

## PutItem Resolver — Create/Replace

### Request (simple, all args as attributes)
```vtl
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($context.args.id),
    },
    "attributeValues" : $util.dynamodb.toMapValuesJson($context.args)
}
```

### Response
```vtl
$utils.toJson($ctx.result)
```

## PutItem Resolver — With CreatedBy

### Request (e.g., Mutation-updateScope.request — actually a PutItem)
```vtl
#set($args = $context.args)
$util.qr($args.put("createdBy", $ctx.identity.username))
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id),
    },
    "attributeValues" : $util.dynamodb.toMapValuesJson($args)
}
```

## UpdateItem Resolver — Expression-Based

### Request (e.g., Mutation-updateApplicationStream.request)
```vtl
{
  "version" : "2017-02-28",
  "operation" : "UpdateItem",
  "key" : {
    "id" : { "S" : "${ctx.args.application.id}" }
  },
  "update" : {
    "expression" : "SET programId = :programId, energyCompanyId = :energyCompanyId, facility = :facility, customerId = :customerId",
    "expressionValues": {
      ":programId" : $util.dynamodb.toDynamoDBJson($ctx.args.application.programId),
      ":energyCompanyId" : $util.dynamodb.toDynamoDBJson($ctx.args.application.energyCompanyId),
      ":facility" : $util.dynamodb.toDynamoDBJson($ctx.args.application.facility),
      ":customerId" : $util.dynamodb.toDynamoDBJson($ctx.args.application.customerId)
    }
  }
}
```

## UpdateItem Resolver — With Condition

### Request (e.g., Mutation-updateExistingConditionStream.request)
```vtl
{
    "version" : "2017-02-28",
    "operation" : "UpdateItem",
    "key" : {
        "id" : { "S" : "${context.arguments.id}" }
    },
    "condition" : {
        "expression" : "attribute_exists(id)"
    },
    "update" : {
        "expression" : "SET recommendations = :recommendations, needsNewRecommendations = :needsNewRecommendations, modifiedBy = :modifiedBy",
        "expressionValues": {
            ":modifiedBy" : { "S": "${context.identity.username}" },
            ":recommendations" : $util.dynamodb.toListJson(${context.arguments.recommendations}),
            ":needsNewRecommendations" : $util.dynamodb.toDynamoDBJson($context.arguments.needsNewRecommendations)
        }
    }
}
```

## DeleteItem Resolver

### Request
```vtl
{
    "version" : "2017-02-28",
    "operation" : "DeleteItem",
    "key" : {
        "id" : { "S" : "${ctx.args.id}" }
    }
}
```

### Response
```vtl
$util.toJson($ctx.result)
```

## BatchGetItem Resolver (Prospector)

### Request
```vtl
#set($ids = [])
#foreach($id in ${ctx.args.ids})
    #set($map = {})
    $util.qr($map.put("id", $util.dynamodb.toString($id)))
    $util.qr($ids.add($map))
#end
{
    "version" : "2018-05-29",
    "operation" : "BatchGetItem",
    "tables" : {
        "${TableName}": {
            "keys": $util.toJson($ids),
            "consistentRead": false
        }
    }
}
```

## Notes on VTL Inconsistencies

The codebase has minor inconsistencies that are established patterns:
- `$util` vs `$utils` — both work, `$util` is standard
- `$ctx` vs `$context` — both work, `$ctx` is shorthand
- `$ctx.args` vs `$context.arguments` — both work
- Key format: `$util.dynamodb.toDynamoDBJson()` vs `{ "S" : "${...}" }` — both used
- Some "update" mutations actually use PutItem (full replace) instead of UpdateItem

These inconsistencies should be preserved when working in existing code but new resolvers should prefer:
- `$util` (not `$utils`)
- `$ctx` (not `$context`)
- `$ctx.args` (not `$context.arguments`)
- `$util.dynamodb.toDynamoDBJson()` for type conversion
