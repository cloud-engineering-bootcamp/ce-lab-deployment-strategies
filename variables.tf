variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

# S3 bucket names are globally unique across all AWS accounts, so the lab's
# plain "deploy-lab" prefix collides with every other student's buckets.
# The account owner's GitHub handle is appended to keep it unique. The same
# value is set as PROJECT_NAME in both workflows.
variable "project_name" {
  description = "Project name used in bucket naming"
  type        = string
  default     = "deploy-lab-draian123"
}
