f"""
Lambda function to manage data sources in Amazon Managed Grafana

This Lambda function is used to create/delete data sources in Amazon Managed Grafana.

The input `event` is a JSON object which should be formatted like so:

```json
{
  "action": "create",
  "name": "amp-dev",
  "type": "grafana-amazonprometheus-datasource",
  "url": "https://aps-workspaces.eu-west-1.amazonaws.com/workspaces/ws-xxxxxxxx/"
}
```

The `action` field is required and must be either `create` or `delete`.
The `name` field is required and must be the name of the data source.
The `type` field is required only if `action` is `create` and must be the type of the data source.
The `url` field is required only if `action` is `create` and must be the URL of the data source.

The Lambda function will return a JSON object with the following fields:

```json
{
  "success": true,
  "message": "Lambda function executed successfully"
}
```

or

```json
{
  "success": false,
  "message": "The field 'action' is required"
}
```

"""

import logging
import os
import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

amg_workspace_id = os.environ['AMG_WORKSPACE_ID']
amg_service_account_id = os.environ['AMG_SERVICE_ACCOUNT_ID']
aws_region = os.environ['AWS_REGION']


def lambda_handler(event, context):
  action = event['action']
  name = event['name']
  logger.info(f"datasrc started, action=`{action}`, name=`{name}`")

  amg_client = boto3.client('grafana', region_name=aws_region)
  resp = amg_client.create_workspace_service_account_token(
    name='datasrc-lambda',
    secondsToLive=120,
    serviceAccountId=amg_service_account_id,
    workspaceId=amg_workspace_id
  )
  token = resp['serviceAccountToken']['key']

  resp = amg_client.describe_workspace(
    workspaceId=amg_workspace_id
  )
  endpoint = resp['workspace']['endpoint']

  if action == "create":
    requests.post(
      f"{endpoint}/api/datasources",
      headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
      },
      json={
        'name': name,
        'type': event['type'],
        'access': "proxy",
        'url': event['url'],
        'jsonData': {
          'httpMethod': "POST",
          'sigV4Auth': True,
          'sigV4AuthType': "default",
          'sigV4Region': aws_region
        }
      }
    )
  else:
    requests.delete(
      f"{endpoint}/api/datasources/{name}",
      headers={
        'Authorization': f'Bearer {token}',
      }
    )

  return {
      "success": True,
      "message": f"Data source `{name}` successfully {action}d"
  }
