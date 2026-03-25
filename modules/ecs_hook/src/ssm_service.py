import boto3
import logging
from botocore.exceptions import ClientError
from enum import Enum

logger = logging.getLogger()

SSM_PARAMETER_PREFIX = "/ecs-deploy/"


class DeployStatus(Enum):
    IN_PROGRESS = "IN_PROGRESS"
    CONFIRMED = "CONFIRMED"
    UNKNOWN = "UNKNOWN"


def _param_name(deploy_id: str) -> str:
    """Convert deployment ARN to SSM parameter name."""
    safe_id = deploy_id.rsplit("/", 1)[-1] if "/" in deploy_id else deploy_id
    return f"{SSM_PARAMETER_PREFIX}{safe_id}"


def get_deploy_status(deploy_id: str) -> DeployStatus:
    try:
        ssm = boto3.client("ssm")
        response = ssm.get_parameter(Name=_param_name(deploy_id))
        value = response["Parameter"]["Value"]
        logger.info(f"SSM status for {deploy_id}: {value}")
        return DeployStatus(value)
    except ClientError as e:
        if e.response["Error"]["Code"] == "ParameterNotFound":
            logger.info(f"No SSM parameter for {deploy_id}")
            return DeployStatus.UNKNOWN
        logger.error(f"SSM get error: {e}")
        return DeployStatus.UNKNOWN
    except (ValueError, Exception) as e:
        logger.error(f"Unexpected error getting deploy status: {e}")
        return DeployStatus.UNKNOWN


def set_deploy_status(deploy_id: str, status: DeployStatus) -> None:
    try:
        ssm = boto3.client("ssm")
        ssm.put_parameter(
            Name=_param_name(deploy_id),
            Value=status.value,
            Type="String",
            Overwrite=True,
        )
        logger.info(f"SSM status set to {status.value} for {deploy_id}")
    except ClientError as e:
        logger.error(f"SSM put error: {e}")
        raise


def delete_deploy_status(deploy_id: str) -> None:
    try:
        ssm = boto3.client("ssm")
        ssm.delete_parameter(Name=_param_name(deploy_id))
        logger.info(f"SSM parameter deleted for {deploy_id}")
    except ClientError as e:
        if e.response["Error"]["Code"] != "ParameterNotFound":
            logger.error(f"SSM delete error: {e}")
            raise
