from datetime import datetime
import boto3
import logging
from botocore.exceptions import ClientError
from enum import Enum

# Configure logging
logger = logging.getLogger()

DYNAMODB_TABLE_NAME = "ecs_service_hook_state"

class TableStatus(Enum):
    IN_PROGRESS = "IN_PROGRESS"
    CONFIRMED = "CONFIRMED"
    FINISH = "FINISH"
    UNKNOWN = "UNKNOWN"

def getTableStatus(deploy_id: str):
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        response = table.get_item(Key={'deploy_id': deploy_id})
        
        logger.info(f"DynamoDB get_item response: {response}")
        
        item = response.get('Item', {})
        if not item:
            logger.warning(f"No item found for deploy_id: {deploy_id}")
            return TableStatus.UNKNOWN
            
        status_value = item.get('status', TableStatus.UNKNOWN.value)
        logger.info(f"Retrieved status: {status_value} for deploy_id: {deploy_id}")
        return TableStatus(status_value)
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"DynamoDB ClientError ({error_code}): {e}")
        if error_code == 'ResourceNotFoundException':
            logger.error(f"Table {DYNAMODB_TABLE_NAME} not found")
        return TableStatus.UNKNOWN
    except ValueError as e:
        logger.error(f"Invalid status value in DynamoDB item: {e}")
        return TableStatus.UNKNOWN
    except Exception as e:
        logger.error(f"Unexpected error getting table status: {e}")
        return TableStatus.UNKNOWN

def createTableStatus(deploy_id: str, status: TableStatus):
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        response = table.put_item(
            Item={
                'deploy_id': deploy_id,
                'status': status.value,
                'createdAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat()
            },
            ConditionExpression="attribute_not_exists(deploy_id)"
        )
        logger.info(f"Status inserted: {status.value}, Response: {response}")
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ConditionalCheckFailedException':
            logger.warning(f"Item already exists for deploy_id: {deploy_id}")
        elif error_code == 'ResourceNotFoundException':
            logger.error(f"Table {DYNAMODB_TABLE_NAME} not found")
        else:
            logger.error(f"DynamoDB ClientError ({error_code}): {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error creating table status: {e}")
        raise

def updateTableStatus(deploy_id: str, status: TableStatus):
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        response = table.update_item(
            Key={'deploy_id': deploy_id},
            UpdateExpression="SET #s = :s, updatedAt = :updatedAt",
            ExpressionAttributeNames={
                '#s': 'status',
            },
            ExpressionAttributeValues={
                ':s': status.value,
                ':updatedAt': datetime.utcnow().isoformat()
            },
            ReturnValues="UPDATED_NEW"
        )
        logger.info(f"Status updated to {status.value}: {response}")
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            logger.error(f"Table {DYNAMODB_TABLE_NAME} not found")
        elif error_code == 'ValidationException':
            logger.error(f"Invalid update expression: {e}")
        else:
            logger.error(f"DynamoDB ClientError ({error_code}): {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error updating table status: {e}")
        raise