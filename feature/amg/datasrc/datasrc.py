"""
Lambda function to manage data sources in Amazon Managed Grafana

This Lambda function is used to create/delete data sources in Amazon Managed Grafana.

The input `event` is a JSON object which should be formatted like so:

```json
{
  "tf": {
    "action": "create"
  },
  "name": "amp-dev",
  "type": "grafana-amazonprometheus-datasource",
  "url": "https://aps-workspaces.eu-west-1.amazonaws.com/workspaces/ws-xxxxxxxx/",
  "role": "ARN_OF_IAM_ROLE_TO_ASSUME"
}
```

The `action` field is required and must be either `create`, `update` or `delete`.
The `name` field is required and must be the name of the data source.
The `type` field is required only if `action` is `create` and must be the type of the data source.
The `url` field is required only if `action` is `create` and must be the URL of the data source.
The `role` field is the IAM role AMG can assume to access the data source.
"""

import json
import logging
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

amg_workspace_id = os.environ['AMG_WORKSPACE_ID']
amg_service_account_id = os.environ['AMG_SERVICE_ACCOUNT_ID']
aws_region = os.environ['AWS_REGION']
http_timeout_seconds = 10


def _grafana_request(method, url, token, body=None):
  headers = {
    'Authorization': f'Bearer {token}'
  }
  data = None
  if body is not None:
    headers['Content-Type'] = 'application/json'
    data = json.dumps(body).encode('utf-8')

  request = urllib.request.Request(url, data=data, headers=headers, method=method)
  try:
    with urllib.request.urlopen(request, timeout=http_timeout_seconds) as response:
      return response.status, response.read().decode('utf-8')
  except urllib.error.HTTPError as error:
    return error.code, error.read().decode('utf-8')


def lambda_handler(event, context):
  action = event['tf']['action']
  name = event['name']
  logger.info(f"datasrc started, action=`{action}`, name=`{name}`")

  amg_client = boto3.client('grafana', region_name=aws_region)

  # Get a Grafana token for the service account
  ts = int(time.time())
  resp = amg_client.create_workspace_service_account_token(
    name=f"datasrc-lambda-{ts}",
    secondsToLive=120,
    serviceAccountId=amg_service_account_id,
    workspaceId=amg_workspace_id
  )
  token = resp['serviceAccountToken']['key']
  token_id = resp['serviceAccountToken']['id']

  try:
    # Get the workspace endpoint
    resp = amg_client.describe_workspace(
      workspaceId=amg_workspace_id
    )
    endpoint = "https://" + resp['workspace']['endpoint']
    encoded_name = urllib.parse.quote(name, safe='')
    payload = {
      'name': name,
      'type': event['type'],
      'access': "proxy",
      'url': event['url'],
      'jsonData': {
        'httpMethod': "POST",
        'sigV4Auth': True,
        'sigV4AuthType': "default",
        'sigV4Region': aws_region,
        'assumeRoleArn': event['role']
      }
    }

    if action == "create":
      status, text = _grafana_request(
        'GET',
        f"{endpoint}/api/datasources/name/{encoded_name}",
        token
      )
      if status == 200:
        logger.info(f"Data source `{name}` already exists, assuming `update` action")
        action = "update"

      else:
        status, text = _grafana_request(
          'POST',
          f"{endpoint}/api/datasources",
          token,
          payload
        )
        if status != 200:
          raise RuntimeError(f"Failed to create data source `{name}`: {text}")

    if action == "update":
      status, text = _grafana_request(
        'GET',
        f"{endpoint}/api/datasources/name/{encoded_name}",
        token
      )
      if status != 200:
        raise RuntimeError(f"Failed to get data source `{name}`: {text}")

      datasource_id = json.loads(text)['id']
      status, text = _grafana_request(
        'PUT',
        f"{endpoint}/api/datasources/{datasource_id}",
        token,
        payload
      )
      if status != 200:
        raise RuntimeError(f"Failed to update data source `{name}`: {text}")

    elif action == "delete":
      status, text = _grafana_request(
        'DELETE',
        f"{endpoint}/api/datasources/name/{encoded_name}",
        token
      )
      if status != 200:
        raise RuntimeError(f"Failed to delete data source `{name}`: {text}")

    elif action == "create":
      pass  # Already handled above

    else:
      raise ValueError(f"Invalid action: {action}")

  finally:
    amg_client.delete_workspace_service_account_token(
      tokenId=token_id,
      serviceAccountId=amg_service_account_id,
      workspaceId=amg_workspace_id
    )

  logger.info(f"Data source `{name}` successfully {action}d")
