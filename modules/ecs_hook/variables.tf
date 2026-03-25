variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL for deploy notifications"
  type        = string
  default     = ""
  sensitive   = true
}