"""
ECS Deployment Lifecycle Hook Handler

Handles Blue-Green deployment lifecycle events:
- PRE_SCALE_UP: Record deployment start, notify Slack
- POST_TEST_TRAFFIC_SHIFT: Check approval status (SSM), notify Slack

Approval is managed externally via GitHub Actions, which writes
CONFIRMED to SSM Parameter Store after manual approval.
"""

import enum
import logging
from dataclasses import dataclass

from ssm_service import DeployStatus, get_deploy_status, set_deploy_status, delete_deploy_status
from slack_notifier import notify

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
    hook_event = HookEvent(event)
    lifecycle_stage = hook_event.lifecycle_stage
    deploy_id = hook_event.resource_arn
    logger.info(f"Received event: stage={lifecycle_stage.value}, deploy_id={deploy_id}")

    if not deploy_id:
        logger.error("resourceArn is missing")
        return {"hookStatus": ResultStatus.FAILED.value}
    if lifecycle_stage == HookStatus.UNKNOWN:
        logger.error(f"Unknown lifecycle stage")
        return {"hookStatus": ResultStatus.FAILED.value}

    if lifecycle_stage == HookStatus.PRE_SCALE_UP:
        return handle_pre_scale_up(deploy_id)
    elif lifecycle_stage == HookStatus.POST_TEST_TRAFFIC_SHIFT:
        return handle_post_test_traffic_shift(deploy_id)
    else:
        logger.warning(f"Unhandled lifecycle stage: {lifecycle_stage.value}")
        return {"hookStatus": ResultStatus.FAILED.value}


def handle_pre_scale_up(deploy_id: str):
    try:
        set_deploy_status(deploy_id, DeployStatus.IN_PROGRESS)
        notify("PRE_SCALE_UP", deploy_id, "started", "New deployment scaling up green tasks.")
        return {"hookStatus": ResultStatus.SUCCEEDED.value}
    except Exception as e:
        logger.error(f"Error in PRE_SCALE_UP: {e}")
        notify("PRE_SCALE_UP", deploy_id, "failed", f"Error: {e}")
        return {"hookStatus": ResultStatus.FAILED.value}


def handle_post_test_traffic_shift(deploy_id: str):
    try:
        current = get_deploy_status(deploy_id)

        if current == DeployStatus.IN_PROGRESS:
            notify(
                "POST_TEST_TRAFFIC_SHIFT",
                deploy_id,
                "waiting",
                "Test traffic shifted. Waiting for approval via GitHub Actions.",
            )
            return {"hookStatus": ResultStatus.IN_PROGRESS.value}

        elif current == DeployStatus.CONFIRMED:
            delete_deploy_status(deploy_id)
            notify(
                "POST_TEST_TRAFFIC_SHIFT",
                deploy_id,
                "confirmed",
                "Approval received. Shifting production traffic.",
            )
            return {"hookStatus": ResultStatus.SUCCEEDED.value}

        else:
            notify("POST_TEST_TRAFFIC_SHIFT", deploy_id, "failed", f"Unexpected status: {current.value}")
            return {"hookStatus": ResultStatus.FAILED.value}

    except Exception as e:
        logger.error(f"Error in POST_TEST_TRAFFIC_SHIFT: {e}")
        notify("POST_TEST_TRAFFIC_SHIFT", deploy_id, "failed", f"Error: {e}")
        return {"hookStatus": ResultStatus.FAILED.value}
