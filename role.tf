resource "aws_iam_role" "role_for_the_ecs_tasks" {
  name = "role_for_the_ecs_tasks"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ECS Task Execution Policy to access ECR, CloudWatch Logs, CloudWatch Metrics, and Auto Scaling
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs_task_execution_policy"
  description = "Policy for ECS task execution to access ECR, CloudWatch Logs, CloudWatch metrics, and Auto Scaling"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutDashboard"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ],
        "Resource": "*"
      },
      # Auto Scaling permissions
      {
        "Effect": "Allow",
        "Action": [
          "application-autoscaling:Describe*",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "application-autoscaling:DeregisterScalableTarget"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Attach the execution policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  role       = aws_iam_role.role_for_the_ecs_tasks.name
}
