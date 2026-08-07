import json
import boto3
from datetime import datetime, timezone
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table('Events')
registrations_table = dynamodb.Table('Registrations')

def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    try:
        event_id = event['pathParameters']['eventId']
        body = json.loads(event.get('body') or '{}')
        email = body.get('email')
        name = body.get('name')

        if not email or not name:
            return response(400, {'error': 'name and email are required'})

        # Check the event exists and has capacity
        event_item = events_table.get_item(Key={'eventId': event_id}).get('Item')
        if not event_item:
            return response(404, {'error': 'Event not found'})

        capacity = int(event_item.get('capacity', 0))
        registered_count = int(event_item.get('registeredCount', 0))

        if registered_count >= capacity:
            return response(409, {'error': 'Event is full'})

        # Prevent duplicate registration for the same email
        existing = registrations_table.get_item(
            Key={'eventId': event_id, 'email': email}
        ).get('Item')
        if existing:
            return response(409, {'error': 'This email is already registered for this event'})

        # Write the registration
        registrations_table.put_item(Item={
            'eventId': event_id,
            'email': email,
            'name': name,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'status': 'confirmed'
        })

        # Increment the event's registered count
        events_table.update_item(
            Key={'eventId': event_id},
            UpdateExpression='SET registeredCount = registeredCount + :inc',
            ExpressionAttributeValues={':inc': 1}
        )

        return response(201, {'message': 'Registration successful', 'eventId': event_id, 'email': email})

    except ClientError as e:
        return response(500, {'error': str(e)})
    except Exception as e:
        return response(500, {'error': str(e)})