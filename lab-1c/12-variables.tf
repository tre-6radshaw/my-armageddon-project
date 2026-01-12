variable "aws_region" {
  description = "AWS Region for the bos fleet to patrol."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for naming. Students should change from 'bos' to their own."
  type        = string
  default     = "bos"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.26.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.26.1.0/24", "10.26.2.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.26.101.0/24", "10.26.102.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-068c0051b15cdb816" # TODO
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admiral" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "Broth3rH00d" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "larrygharris76@gmail.com" # TODO: student supplies
}

variable "domain_name" {
  description = "Base domain students registered (e.g., larryharrisaws.com)."
  type        = string
  default     = "larryharrisaws.com"
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app.larryharrisaws.com)."
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}

variable "enable_alb_access_logs" {
  description = "Whether to create the S3 bucket for ALB access logs"
  type        = bool
  default     = true          # ← choose your preferred default
}

variable "manage_route53_in_terraform" {
  description = "Whether to let Terraform manage creation / updates of the Route 53 hosted zone"
  type        = bool
  default     = true   # ← most people start with true here
}
variable "waf_log_destination" {
  description = "Where to send AWS WAFv2 logs: 'cloudwatch', 'firehose', 's3', or 'none'"
  type        = string
  default     = "none"          # or "cloudwatch" if you want it on by default
  validation {
    condition     = contains(["cloudwatch", "firehose", "s3", "none"], var.waf_log_destination)
    error_message = "Valid values are: cloudwatch, firehose, s3, none."
  }
}

variable "waf_log_retention_days" {
  description = "Number of days to retain WAF CloudWatch log events (0 = never expire)"
  type        = number
  default     = 90          # ← common sensible default; change as needed
}


variable "route53_hosted_zone_id" {
  type        = string
  default     = ""

  validation {
    condition     = var.route53_hosted_zone_id == "" || can(regex("^[A-Z0-9]{21}$", var.route53_hosted_zone_id))
    error_message = "route53_hosted_zone_id must be empty or a valid 21-character Route 53 hosted zone ID (e.g. Z0123456789ABCDEF)."
  }
}

variable "alb_access_logs_prefix" {
  type    = string
  default = ""

  validation {
    condition     = !can(regex("(?i)AWSLogs", var.alb_access_logs_prefix))
    error_message = "alb_access_logs_prefix must NOT contain 'AWSLogs' (case-insensitive) — AWS adds this automatically."
  }
}