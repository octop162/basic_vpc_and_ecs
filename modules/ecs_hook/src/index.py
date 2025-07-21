"""
Event Example: 
{
    "executionDetails": {
        "testTrafficWeights": {},
        "productionTrafficWeights": {},
        "serviceArn": "[ECS Service ARN]",
        "targetServiceRevisionArn": "[ECS Service Revision ARN]"
    },
    "executionId": "[ECS Deployment Execution ID]",
    "lifecycleStage": "POST_TEST_TRAFFIC_SHIFT",
    "resourceArn": "[ECS Deployment Resource ARN]"
}

lifecycleStage can be one of:
https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeploymentLifecycleHook.html
- RECONCILE_SERVICE
- PRE_SCALE_UP
- POST_SCALE_UP
- TEST_TRAFFIC_SHIFT
- POST_TEST_TRAFFIC_SHIFT
- PRODUCTION_TRAFFIC_SHIFT
- POST_PRODUCTION_TRAFFIC_SHIFT
"""
import enum
import logging
from dataclasses import dataclass
from dynamo_service import TableStatus, getTableStatus, createTableStatus, updateTableStatus

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class HookStatus(enum.Enum):
    RECONCILE_SERVICE = "RECONCILE_SERVICE"
    PRE_SCALE_UP = "PRE_SCALE_UP"
    POST_SCALE_UP = "POST_SCALE_UP"
    TEST_TRAFFIC_SHIFT = "TEST_TRAFFIC_SHIFT"
    POST_TEST_TRAFFIC_SHIFT = "POST_TEST_TRAFFIC_SHIFT"
    PRODUCTION_TRAFFIC_SHIFT = "PRODUCTION_TRAFFIC_SHIFT" 
    POST_PRODUCTION_TRAFFIC_SHIFT = "POST_PRODUCTION_TRAFFIC_SHIFT"
    X_MANUAL_CONFIRM = "X_MANUAL_CONFIRM"
    UNKNOWN = "UNKNOWN"

class ResultStatus(enum.Enum):
    SUCCEEDED = "SUCCEEDED"
    FAILED = "FAILED"
    IN_PROGRESS = "IN_PROGRESS"

@dataclass
class HookEvent:
    lifecycle_stage: HookStatus
    resource_arn: str
    def __init__(self, event):
        self.lifecycle_stage = HookStatus(event.get("lifecycleStage", "UNKNOWN"))
        self.resource_arn = event.get("resourceArn", "")

def handler(event, context):
    # Parse event
    hook_event = HookEvent(event)
    lifecycle_stage = hook_event.lifecycle_stage
    deploy_id = hook_event.resource_arn
    logger.info(f"Received event: {hook_event}")
    
    if not deploy_id:
        logger.error("resourceArn is missing in the event.")
        return {"hookStatus": ResultStatus.FAILED.value}
    if lifecycle_stage == HookStatus.UNKNOWN:
        logger.error(f"Unknown lifecycle stage: {lifecycle_stage}")
        return {"hookStatus": ResultStatus.FAILED.value}

    # Route to appropriate handler
    if lifecycle_stage == HookStatus.X_MANUAL_CONFIRM:
        return handle_manual_confirm(deploy_id)
    elif lifecycle_stage == HookStatus.PRE_SCALE_UP:
        return handle_pre_scale_up(deploy_id)
    elif lifecycle_stage == HookStatus.POST_TEST_TRAFFIC_SHIFT:
        return handle_post_test_traffic_shift(deploy_id)
    else:
        logger.warning(f"Unhandled lifecycle stage: {lifecycle_stage}")
        return {"hookStatus": ResultStatus.FAILED.value}

def handle_manual_confirm(deploy_id: str):
    try:
        current_status = getTableStatus(deploy_id)
        if current_status == TableStatus.IN_PROGRESS:
            logger.info("Table status is IN_PROGRESS for X_MANUAL_CONFIRM stage.")
            updateTableStatus(deploy_id, TableStatus.CONFIRMED)
            return {"hookStatus": ResultStatus.IN_PROGRESS.value}
        else:
            logger.warning("Table status is not IN_PROGRESS for X_MANUAL_CONFIRM stage.")
            return {"hookStatus": ResultStatus.FAILED.value}
    except Exception as e:
        logger.error(f"Error handling X_MANUAL_CONFIRM stage: {e}")
        return {"hookStatus": ResultStatus.FAILED.value}

def handle_pre_scale_up(deploy_id: str):
    try:
        createTableStatus(deploy_id, TableStatus.IN_PROGRESS)
        logger.info("Table status set to IN_PROGRESS for PRE_SCALE_UP stage.")
        return {"hookStatus": ResultStatus.SUCCEEDED.value}
    except Exception as e:
        logger.error(f"Error handling PRE_SCALE_UP stage: {e}")
        return {"hookStatus": ResultStatus.FAILED.value}

def handle_post_test_traffic_shift(deploy_id: str):
    try:
        current_status = getTableStatus(deploy_id)
        if current_status == TableStatus.IN_PROGRESS:
            logger.info("Table status is IN_PROGRESS for POST_TEST_TRAFFIC_SHIFT stage.")
            return {"hookStatus": ResultStatus.IN_PROGRESS.value}
        elif current_status == TableStatus.CONFIRMED:
            updateTableStatus(deploy_id, TableStatus.FINISH)
            logger.info("Table status set to FINISH for POST_TEST_TRAFFIC_SHIFT stage.")
            return {"hookStatus": ResultStatus.SUCCEEDED.value}
        else:
            logger.warning("Table status is not IN_PROGRESS or CONFIRMED for POST_TEST_TRAFFIC_SHIFT stage.")
            return {"hookStatus": ResultStatus.FAILED.value}
    except Exception as e:
        logger.error(f"Error handling POST_TEST_TRAFFIC_SHIFT stage: {e}")
        return {"hookStatus": ResultStatus.FAILED.value}

