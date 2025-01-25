variable "name" {
  description = "name of application"
  type        = string
  default     = "harris"
}

data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["shared-*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

resource "aws_instance" "public" {
  ami                         = "ami-04c913012f8977029"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.public.ids[0]
  associate_public_ip_address = true
  key_name                    = "harris-key-pair" #Change to your keyname, e.g. jazeel-key-pair

  tags = {
    Name = "${var.name}-ec2" #Prefix your own name, e.g. jazeel-ec2
  }
}

resource "aws_cloudwatch_metric_alarm" "info_count" {
  alarm_name          = "info-count-breach"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "20" 
  metric_name        = "info-count"
  namespace          = "/moviedb-api/example"
  period             = "60"
  statistic          = "Sum"
  threshold          = "10"  # Set your threshold
  alarm_description  = "This alarm fires when info-count is greater than 10"

  dimensions = {
    InstanceId = aws_instance.public.id
  }

  actions_enabled = true

  alarm_actions = [aws_sns_topic.alarm.arn]  # Add SNS topic ARNs here if you want notifications
}

resource "aws_sns_topic_subscription" "alarm" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = "harris_ita@yahoo.com.sg"
}
