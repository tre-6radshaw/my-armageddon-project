variable "aws_account_id" {
  description = "id of aws account"
  type        = string
  default     = "435830281557"
}

variable "aws_region" {
  description = "AWS Region for the edo fleet to patrol."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Prefix for naming. Students should change from 'edo' to their own."
  type        = string
  default     = "edo"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.81.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.81.1.0/24", "10.81.2.0/24", "10.81.3.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.81.101.0/24", "10.81.102.0/24", "10.81.103.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"] # TODO: student supplies
}

# variable "ec2_ami_id" { # Commented out due to using a data source for the AMI in 07b-launchtemplate.tf
#   description = "AMI ID for the EC2 app host."
#   type        = string
#   default     = "ami-0e5b755eb72aa63d9b816" # TODO
# }

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
  default     = "trebradshaw94@gmail.com" # TODO: student supplies
}

#1c_Bonus_Variables
variable "domain_name" {
  description = "Base domain students registered (e.g., zerotrustzone.dev)."
  type        = string
  default     = "zerotrustzone.dev"
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app.zerotrustzone.dev)."
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
  default     = true # ← choose your preferred default
}

variable "manage_route53_in_terraform" {
  description = "Whether to let Terraform manage creation / updates of the Route 53 hosted zone"
  type        = bool
  default     = true # ← most people start with true here
}
variable "waf_log_destination" {
  description = "Where to send AWS WAFv2 logs: 'cloudwatch', 'firehose', 's3', or 'none'"
  type        = string
  default     = "cloudwatch" # or "cloudwatch" if you want it on by default
  validation {
    condition     = contains(["cloudwatch", "firehose", "s3", "none"], var.waf_log_destination)
    error_message = "Valid values are: cloudwatch, firehose, s3, none."
  }
}

variable "waf_log_retention_days" {
  description = "Number of days to retain WAF CloudWatch log events (0 = never expire)"
  type        = number
  default     = 90 # ← common sensible default; change as needed
}


variable "route53_hosted_zone_id" {
  type    = string
  default = "Z01577161V0KC9A3QVH2K"

  validation {
    condition     = var.route53_hosted_zone_id == "" || can(regex("^[A-Z0-9]{21}$", var.route53_hosted_zone_id))
    error_message = "route53_hosted_zone_id must be empty or a valid 21-character Route 53 hosted zone ID (e.g. Z0123456789ABCDEF)."
  }
}

variable "alb_access_logs_prefix" {
  type    = string
  default = "alb-access-logs"

  validation {
    condition     = !can(regex("(?i)AWSLogs", var.alb_access_logs_prefix))
    error_message = "alb_access_logs_prefix must NOT contain 'AWSLogs' (case-insensitive) — AWS adds this automatically."
  }
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}

### Lab 3
variable "brazil_vpc_cidr" {
  type    = string
  default = "10.55.0.0/16"
}