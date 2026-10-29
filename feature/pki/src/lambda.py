from aws_lambda_powertools import Logger


logger = Logger(service="pki")


@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    f"""
    Lambda handler for the PKI service. This Lambda function can create, update and delete certificates and private keys.

    The event received must had the following pattern:

    ```json
    {
      "action": "upsert",  # Can be "upsert" or "delete"
      "certificateparameters": {
        # JSON object that follows the `CertificateParameters` schema
      }
    }
    ```

    """
    
