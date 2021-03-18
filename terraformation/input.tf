### Variables ###

variable "tags" {
  description = "Default tags for Doll platform"
  type        = map(string)
  default     = {}
}

variable "username" {
  description = "The username for the DB master user"
  type        = string
}
variable "create_random_password" {
  description = "Whether to create random password for RDS primary cluster"
  type        = bool
  default     = true
}
variable "password" {
  description = "The password for the DB master user"
  type        = string
  default     = ""
}

### Data ###

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_s3_bucket" "main" {
  bucket = "doll-platform-artifacts"
}