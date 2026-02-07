# NAT
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway

# NAT EIP
resource "aws_eip" "gru_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# NATGW
resource "aws_nat_gateway" "gru_nat01" {
  allocation_id = aws_eip.gru_nat_eip01.id
  subnet_id     = aws_subnet.gru_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.gru_igw01]
}