

variable "vpc_cidrs" {
  description = "List of CIDR blocks for each VPC"
  type        = list(string)
}

variable "subzone" {
    type        = list(string)
    description = "availability zones"
}

variable "subnetcidr" {
    type        = list(string)
    description = "subnet cidrs"
}

variable "prisubnetcidr" {
    type        = list(string)
    description = "private subnet cidrs"
}

variable "subnetcidrvpc2"{
    type        = list(string)
    description = "subnet cidr of vpc2"
}

variable "subzonevpc2"{
    type        = list(string)
    description = "availability zone of vpc2"
}
variable "ami" {
    type = string
    description = "ami value"
}
variable "type" {
    type = string
    description = "type"
}
variable "amitemplate" {
  type = list(string)
  description = "ami template to pass in autoscaling "
}
variable "amitype" {
  type = string
  description = "ami type to pass in autoscaling "
}

variable "vpc_ids" {
  description = "List of VPC IDs to attach to the Transit Gateway"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}
