# Routes
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

# Public Route Table
resource "aws_route_table" "edo_public_rt01" {
  vpc_id = aws_vpc.edo_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Private Route Table
resource "aws_route_table" "edo_private_rt01" {
  vpc_id = aws_vpc.edo_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Default Public Route
resource "aws_route" "edo_public_default_route" {
  route_table_id         = aws_route_table.edo_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.edo_igw01.id
}

# Default Private Route
resource "aws_route" "edo_private_default_route" {
  route_table_id         = aws_route_table.edo_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.edo_nat01.id
}

# Public Route Associations
resource "aws_route_table_association" "edo_public_rta" {
  count          = length(aws_subnet.edo_public_subnets)
  subnet_id      = aws_subnet.edo_public_subnets[count.index].id
  route_table_id = aws_route_table.edo_public_rt01.id
}

# Private Route Associations
resource "aws_route_table_association" "edo_private_rta" {
  count          = length(aws_subnet.edo_private_subnets)
  subnet_id      = aws_subnet.edo_private_subnets[count.index].id
  route_table_id = aws_route_table.edo_private_rt01.id
}

##########################################################################################################

resource "aws_route" "edo_to_sp_route01" {
  route_table_id         = aws_route_table.edo_private_rt01.id
  destination_cidr_block = "10.55.0.0/16" # Sao Paulo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.edo_tgw01.id
}