variable "vpc_cidrs" {}
variable "subzone" {}
variable "subnetcidr" {}
variable "prisubnetcidr" {}
variable "subnetcidrvpc2"{}
variable "subzonevpc2"{}


resource "aws_vpc" "myvpc" {
    count = length(var.vpc_cidrs)
    cidr_block = element(var.vpc_cidrs,count.index)
    tags = {
      name = "VPC-${count.index+1}"
    }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.myvpc[0].id
  count = length(var.subnetcidr) 
  cidr_block = element(var.subnetcidr,count.index)
  availability_zone = element(var.subzone,count.index)
  tags = {
    name = "public-${count.index+1}"
    }
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.myvpc[0].id
  count = length(var.prisubnetcidr)
  cidr_block = element(var.prisubnetcidr, count.index)
  availability_zone = element(var.subzone, count.index)
  tags = {
    name = "private-${count.index+1}"
  }
}

resource "aws_internet_gateway" "igwVPC1" {
    vpc_id = aws_vpc.myvpc[0].id
}

resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc[0].id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igwVPC1.id
    }
    tags = {
        name = "pubrt-VPC1"
    }
}
resource "aws_route_table_association" "pubrt" {
  count      = length(aws_subnet.public)  
  subnet_id  = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.pubrt.id  
}

resource "aws_eip" "nat" {
    tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = [aws_subnet.public[0].id,aws_subnet.public[1].id]
    tags = {
        name = "nat-gateway"
    }
}

resource "aws_route_table" "prirt" {
    vpc_id = aws_vpc.myvpc[0].id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
      name = "prirt-VPC1"
    }
}

resource "aws_route_table_association" "prirt" {
  count = length(aws_subnet.private)
  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.prirt.id
}

resource "aws_subnet" "publicvpc2" {
    vpc_id = aws_vpc.myvpc[1].id
    count = length(var.subnetcidrvpc2)
    cidr_block = element(var.subnetcidrvpc2,count.index)
    availability_zone = element(var.subzonevpc2,count.index)
    map_public_ip_on_launch = true
    tags = {
        name = "public-subnet-vpc2-${count.index+1}"
    }    
}

resource "aws_internet_gateway" "igwvpc2" {
    vpc_id = aws_vpc.myvpc[1].id
}

resource "aws_route_table" "rtvpc2" {
    vpc_id = aws_vpc.myvpc[1].id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igwvpc2.id
    }
    tags = {
      name = "pubrtvpc2"
    }
}

resource "aws_route_table_association" "pubrtvpc2" {
  count = length(aws_subnet.publicvpc2)
  subnet_id = element(aws_subnet.publicvpc2.*.id, count.index)
  route_table_id = aws_route_table.rtvpc2.id
}

resource "aws_ec2_transit_gateway" "main" {
  description = "Main Transit Gateway"
  amazon_side_asn = 64512  # Adjust ASN if needed
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  vpn_ecmp_support = "enable"
  multicast_support = "disable"  # Adjust if multicast support is needed
}

# Create Transit Gateway Attachments for each VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  count = length(var.vpc_cidrs)

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = element(var.myvpc.id, count.index)
  subnet_ids          = aws_subnet.private[*].id  # Adjust this if you have specific subnets to use

  tags = {
    Name = "TGW-Attachment-${count.index + 1}"
  }
}

# Create a route table association
resource "aws_ec2_transit_gateway_route_table_association" "tgw_route_table_assoc" {
  count = length(var.myvpc.id)
  
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment[count.index].id
}
