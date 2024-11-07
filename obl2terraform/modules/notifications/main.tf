resource "aws_sqs_queue" "queue" {
  name = var.queue_name
}

resource "aws_sns_topic" "notifications" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}
