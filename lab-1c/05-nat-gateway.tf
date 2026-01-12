# Explanation: bos wants the private base to call home—EIP gives the NAT a stable “holonet address.”
resource "aws_eip" "bos_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# Explanation: NAT is bos’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "bos_nat01" {
  allocation_id = aws_eip.bos_nat_eip01.id
  subnet_id     = aws_subnet.bos_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.bos_igw01]
}
