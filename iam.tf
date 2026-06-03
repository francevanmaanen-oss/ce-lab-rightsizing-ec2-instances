# IAM role that allows EC2 instances to send metrics to CloudWatch
# and be managed via SSM (no SSH required)

resource "aws_iam_role" "cloudwatch_agent" {
  name = "CloudWatchAgentRole-${var.lab_tag}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Lab = var.lab_tag
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = "CloudWatchAgentRole-${var.lab_tag}"
  role = aws_iam_role.cloudwatch_agent.name
}
