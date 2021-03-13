variable "vpc_id" {
    description = "VPC to use"
    default = "vpc-f607208c"
}
variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "0.0.0.0/0"
}