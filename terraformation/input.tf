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
variable "password" {
  description = "The password for the DB master user"
  type        = string
}

### Data ###

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_s3_bucket" "main" {
  bucket = "doll-platform-artifacts"
}