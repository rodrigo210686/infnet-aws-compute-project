variable "vpc_cidr" {}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "us_availability_zone" {}
variable "cidr_private_subnet" {}
variable "public_subnet_ipv6_prefixes" {}
variable "private_subnet_ipv6_prefixes" {}


# Setup VPC
resource "aws_vpc" "infnet_proj_1_vpc_us_east_1" {
  cidr_block = var.vpc_cidr

  # Enable IPv6 for the VPC
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpc_name
  }
}


# Setup public subnet
resource "aws_subnet" "infnet_proj_1_public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.infnet_proj_1_vpc_us_east_1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.us_availability_zone, count.index)


  tags = {
    Name = "infnet-proj-public-subnet-${count.index + 1}"
  }
}

# Setup private subnet
resource "aws_subnet" "infnet_proj_1_private_subnets" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.infnet_proj_1_vpc_us_east_1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.us_availability_zone, count.index)


  tags = {
    Name = "infnet-proj-private-subnet-${count.index + 1}"
  }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "infnet_proj_1_public_internet_gateway" {
  vpc_id = aws_vpc.infnet_proj_1_vpc_us_east_1.id
  tags = {
    Name = "infnet-proj-1-igw"
  }
}

# Public Route Table
resource "aws_route_table" "infnet_proj_1_public_route_table" {
  vpc_id = aws_vpc.infnet_proj_1_vpc_us_east_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infnet_proj_1_public_internet_gateway.id
  }
  tags = {
    Name = "infnet-proj-1-public-rt"
  }
}

# Public Route Table and Public Subnet Association
resource "aws_route_table_association" "infnet_proj_1_public_rt_subnet_association" {
  count          = length(aws_subnet.infnet_proj_1_public_subnets)
  subnet_id      = aws_subnet.infnet_proj_1_public_subnets[count.index].id
  route_table_id = aws_route_table.infnet_proj_1_public_route_table.id
}

# Nat Gateway Allocation EIP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "infnet-proj-1-nat-eip"
  }
}    

# Nat Gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [ aws_eip.nat_eip ]
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.infnet_proj_1_public_subnets[0].id
 tags = {
   Name = "infnet-proj-1-nat-gateway"
 }
}  


# Private Route Table
resource "aws_route_table" "infnet_proj_1_private_route_table" {
  vpc_id = aws_vpc.infnet_proj_1_vpc_us_east_1.id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "infnet-proj-1-private-rt"
  }
}

# Private Route Table and private Subnet Association
resource "aws_route_table_association" "infnet_proj_1_private_rt_subnet_association" {
  depends_on = [aws_nat_gateway.nat_gateway]
  count          = length(aws_subnet.infnet_proj_1_private_subnets)
  subnet_id      = aws_subnet.infnet_proj_1_private_subnets[count.index].id
  route_table_id = aws_route_table.infnet_proj_1_private_route_table.id
}

output "infnet_proj_1_vpc_id" {
  value = aws_vpc.infnet_proj_1_vpc_us_east_1.id
}

output "infnet_proj_1_public_subnets" {
  value = aws_subnet.infnet_proj_1_public_subnets.*.id
}

output "infnet_proj_1_private_subnets" {
  value = aws_subnet.infnet_proj_1_private_subnets.*.id
}

output "infnet_proj_1_private_subnets_cidr_blocks" {
  value = aws_subnet.infnet_proj_1_private_subnets.*.cidr_block
  
}

output "subnet_id_output" {
  value = aws_subnet.infnet_proj_1_private_subnets.*.id
} 