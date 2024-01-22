import json

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    for record in event['Records']:
        # Extract the message body from the SQS record
        message_body = json.loads(record['body'])

        # Your processing logic goes here
        process_sqs_message(message_body)

    return {
        'statusCode': 200,
        'body': json.dumps('SQS messages processed successfully!')
    }

def process_sqs_message(message_body):
    print("Processing SQS message:")
    print("Body:", message_body)
