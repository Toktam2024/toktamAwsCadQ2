provider "aws" {
  region = "us-east-2"
}

# Create an S3 Bucket
resource "aws_s3_bucket" "toktam_S3Bucket" {
  bucket = "toktam-s3-bucket"
}

# Create an IAM Role
resource "aws_iam_role" "toktam30_IAMRole" {
  name = "toktam30-iam-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Create an IAM Policy
resource "aws_iam_policy" "toktam30_IAMPolicy" {
  name        = "toktam30-iam-policy"
  description = "Sample IAM policy for toktam30 IAM role"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : aws_s3_bucket.toktam_S3Bucket.arn
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "toktam30_IAMRolePolicyAttachment" {
  role       = aws_iam_role.toktam30_IAMRole.name
  policy_arn = aws_iam_policy.toktam30_IAMPolicy.arn
}

# Create a Security Group
resource "aws_security_group" "toktam_SecurityGroup" {
  name        = "toktam-security-group"
  description = "Security group with port 3306 open"
  vpc_id      = "vpc-0264c5466be78c0d4"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "toktam_RDSInstance" {
  identifier             = "toktam-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "metroc1234"
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.toktam_SecurityGroup.id]
}

# Create a KMS Key
resource "aws_kms_key" "toktam_KMSKey" {
  description             = "toktam KMS Key"
  deletion_window_in_days = 30
  tags = {
    Name = "toktam-kms-key"
  }
}


# Create an Application Load Balancer
resource "aws_lb" "toktam_ALB" {
  name               = "toktam-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.toktam_SecurityGroup.id]
  subnets            = ["subnet-04ea19888f192a0fd", "subnet-0a985e1b46ac8521f"]
}

# Create a Launch Configuration
resource "aws_launch_configuration" "example" {
  name          = "example-launch-configuration"
  image_id      = "ami-0647086318eb3b918"
  instance_type = "t2.micro"
}

# Create an AutoScaling Group
resource "aws_autoscaling_group" "toktam_ASG" {
  name                      = "toktam-asg"
  launch_configuration      = aws_launch_configuration.example.id
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  vpc_zone_identifier       = ["subnet-04ea19888f192a0fd", "subnet-0a985e1b46ac8521f"]
  health_check_type         = "EC2"
  health_check_grace_period = 300
}


# Create a Glue Job
resource "aws_glue_job" "toktam_GlueJob" {
  name     = "toktam-glue-job"
  role_arn = aws_iam_role.toktam30_IAMRole.arn
  command {
    name            = "glueetl"
    script_location = "s3://toktam-s3-bucket/sample_script.py"
  }
}