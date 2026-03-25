import json
import logging
import os
from urllib.request import Request, urlopen
from urllib.error import URLError

logger = logging.getLogger()

SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")


def notify(stage: str, deploy_id: str, status: str, detail: str = "") -> None:
    if not SLACK_WEBHOOK_URL:
        logger.warning("SLACK_WEBHOOK_URL not set, skipping notification")
        return

    color_map = {
        "started": "#36a64f",
        "waiting": "#ff9900",
        "confirmed": "#36a64f",
        "succeeded": "#36a64f",
        "failed": "#dc3545",
    }

    short_id = deploy_id.rsplit("/", 1)[-1][:12] if "/" in deploy_id else deploy_id[:12]

    payload = {
        "attachments": [
            {
                "color": color_map.get(status, "#808080"),
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"ECS Deploy: {stage}",
                        },
                    },
                    {
                        "type": "section",
                        "fields": [
                            {"type": "mrkdwn", "text": f"*Status:*\n{status.upper()}"},
                            {"type": "mrkdwn", "text": f"*Deploy ID:*\n{short_id}"},
                        ],
                    },
                ],
            }
        ]
    }

    if detail:
        payload["attachments"][0]["blocks"].append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": detail},
            }
        )

    try:
        req = Request(
            SLACK_WEBHOOK_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        urlopen(req, timeout=5)
        logger.info(f"Slack notification sent: {stage} - {status}")
    except URLError as e:
        logger.error(f"Slack notification failed: {e}")
