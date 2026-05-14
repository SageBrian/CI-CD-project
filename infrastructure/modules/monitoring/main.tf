# modules/monitoring/main.tf
# CloudWatch alarms + SNS for pipeline failure notifications
# Shows employers you think about observability — a senior engineer habit

# ─── SNS Topic ─────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

# Email subscription — you'll get a confirmation email to activate
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─── CloudWatch Event Rule — Pipeline Failure ──────────────────────────────────
# EventBridge (formerly CloudWatch Events) catches pipeline failures
resource "aws_cloudwatch_event_rule" "pipeline_failure" {
  name        = "${var.project_name}-${var.environment}-pipeline-failure"
  description = "Fires when the CI/CD pipeline fails"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state    = ["FAILED"]
      pipeline = [var.pipeline_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline_failure_sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_failure.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}

# Allow EventBridge to publish to SNS
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.alerts.arn
    }]
  })
}

# ─── CloudWatch Dashboard ──────────────────────────────────────────────────────
# Visual dashboard in AWS console — screenshot this for your portfolio
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "CodeBuild - Build Duration"
          region = "us-east-1"
          metrics = [
            ["AWS/CodeBuild", "Duration", "ProjectName", "${var.project_name}-${var.environment}-build"]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "CodeBuild - Failed Builds"
          region = "us-east-1"
          metrics = [
            ["AWS/CodeBuild", "FailedBuilds", "ProjectName", "${var.project_name}-${var.environment}-build"]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}
