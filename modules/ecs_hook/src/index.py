from datetime import datetime

def handler(event, context):
    current_time = datetime.now()
    current_hour = current_time.hour
    current_minute = current_time.minute
    current_total_minutes = current_hour * 60 + current_minute

    HOUR = 2
    MINUTE = 5
    target_minutes = HOUR * 60 + MINUTE
    is_after = current_total_minutes >= target_minutes
    if is_after:
        print("SUCCEEDED")
        return {
            "hookStatus": "SUCCEEDED"
        }
    else:
        print("IN_PROGRESS")
        return {
            "hookStatus": "IN_PROGRESS"
        }