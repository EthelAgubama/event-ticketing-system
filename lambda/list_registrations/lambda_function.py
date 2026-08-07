import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Registrations')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, default=decimal_default)
    }

def lambda_handler(event, context):
    try:
        event_id = event['pathParameters']['eventId']

        result = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('eventId').eq(event_id)
        )
        items = result.get('Items', [])

        return response(200, items)
    except Exception as e:
        return response(500, {'error': str(e)})