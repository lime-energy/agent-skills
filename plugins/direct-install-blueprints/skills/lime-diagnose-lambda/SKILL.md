---
name: lime-diagnose-lambda
description: "Diagnose Lambda function issues — CloudWatch logs, DynamoDB stream health, cold starts, throttling, error patterns. Use when debugging Lambda failures or performance issues."
---

# Diagnose Lambda

Query CloudWatch logs, trace DynamoDB stream flows, and detect common Lambda failure patterns.

## Reference Material

- `${CLAUDE_PLUGIN_ROOT}/references/lambda-patterns.md` — Handler patterns, error handling conventions
- `${CLAUDE_PLUGIN_ROOT}/references/architecture.md` — Stream processing paths

## Common Diagnostics

### Recent Errors
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function-name> \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --query 'events[].message' \
  --output text
```

### CloudWatch Logs Insights
```
fields @timestamp, @message
| filter @message like /ERROR|Exception|ECONNREFUSED|ESOCKETTIMEDOUT/
| sort @timestamp desc
| limit 50
```

### Stream Health (Iterator Age)
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name IteratorAge \
  --dimensions Name=TableName,Value=<table-name> \
  --start-time <1-hour-ago> \
  --end-time <now> \
  --period 300 \
  --statistics Maximum
```

High iterator age (>60s) indicates processing lag.

### Cold Start Analysis
```
fields @timestamp, @duration, @initDuration
| filter ispresent(@initDuration)
| stats count() as coldStarts, avg(@initDuration) as avgColdStart, max(@initDuration) as maxColdStart
```

### Throttling Detection
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=<function-name> \
  --start-time <1-hour-ago> \
  --end-time <now> \
  --period 300 \
  --statistics Sum
```

## Common Failure Patterns

| Pattern | Log Signature | Likely Cause | Fix |
|---------|-------------|-------------|-----|
| Connection refused | `ECONNREFUSED` | AppSync endpoint unreachable | Check APPSYNC_API env var, VPC config |
| Socket timeout | `ESOCKETTIMEDOUT` | Downstream service slow | Increase timeout, add retry |
| Conditional check failed | `ConditionalCheckFailedException` | Expected in concurrent updates | Usually safe to ignore (by convention) |
| Out of memory | `Runtime exited with error: signal: killed` | Memory limit exceeded | Increase MemorySize in SAM |
| Timeout | `Task timed out after X seconds` | Function too slow | Increase Timeout, optimize code |

## End-to-End Trace

To trace a record through the full pipeline:
1. Find the DynamoDB stream record by ID in the source table's stream
2. Check the Lambda invocation logs for that record's processing
3. Verify the AppSync mutation was sent (look for `Sent` log from RxJS pipeline)
4. Check AppSync subscription delivery if real-time update was expected
