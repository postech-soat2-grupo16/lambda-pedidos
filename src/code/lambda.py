import json
import requests


def main(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    for record in event['Records']:
        message_body = json.loads(record['body'])
        process_sqs_message(message_body)
        return notify_payments(message_body)

def process_sqs_message(message_body):
    print("Processing SQS message:")
    print("Body:", message_body)

def notify_payments(body):
    order_id = body['order_id']
    url_base = os.environ['URL_BASE']
    endpoint = os.environ['ENDPOINT'].replace("id", order_id)
    url = url_base + '/' + endpoint

    try:
        response = requests.get(url)

        if response.status_code == 200:
            print('Response BODY: ', response.body)
            return {
                'statusCode': 200,
                'body': json.dumps('Pedido {order_id} Message processed successfully!')
            }
        else:
            return {
                'statusCode': response.status_code,
                'body': json.dumps('Pedido {order_id} Message Error!')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps('Pedido {order_id} Message Exception Error!')
        }