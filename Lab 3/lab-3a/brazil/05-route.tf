# Routes
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

# Public Route Table
resource "aws_route_table" "gru_public_rt01" {
  vpc_id = aws_vpc.gru_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Private Route Table
resource "aws_route_table" "gru_private_rt01" {
  vpc_id = aws_vpc.gru_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Default Public Route
resource "aws_route" "gru_public_default_route" {
  route_table_id         = aws_route_table.gru_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gru_igw01.id
}

# Default Private Route
resource "aws_route" "gru_private_default_route" {
  route_table_id         = aws_route_table.gru_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gru_nat01.id
}

# Public Route Associations
resource "aws_route_table_association" "gru_public_rta" {
  count          = length(aws_subnet.gru_public_subnets)
  subnet_id      = aws_subnet.gru_public_subnets[count.index].id
  route_table_id = aws_route_table.gru_public_rt01.id
}

# Private Route Associations
resource "aws_route_table_association" "gru_private_rta" {
  count          = length(aws_subnet.gru_private_subnets)
  subnet_id      = aws_subnet.gru_private_subnets[count.index].id
  route_table_id = aws_route_table.gru_private_rt01.id
}

################################################################SHINJUKU##########################################################


# Explanation: gru knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "gru_to_tokyo_route01" {
  provider               = aws.saopaulo
  route_table_id         = aws_route_table.gru_private_rt01.id
  destination_cidr_block = "10.81.0.0/16" # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.gru_tgw01.id
}