provider "AWS" {
    region = "ap-south-1"
}

module "vpc" {
    source = file("./vpc")
    vpc_cidrs = [ "10.0.0.0/16","192.168.0.0/16" ]
    subzone = ["ap-south-1a","ap-south-1b"]
    prisubnetcidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24","10.0.5.0/24","10.0.6.0/24","10.0.7.0/24","10.0.8.0/24","10.0.9.0/24","10.0.10.0/24", ]
    subnetcidr = ["10.0.11.0/24","10.0.12.0/24"]
    subnetcidrvpc2 = ["192.168.3.0/24"]
    subzonevpc2 =["ap-south-1a"]
}

module "ec2" {
    source = file("./ec2")
    ami = "ami-0182f373e66f89c85"
    type = "t2.micro"
    amitemplate = ["ami-0182f373e66f89c85","ami-0182f373e66f89c85"]
    amitype = "t2.micro"
}