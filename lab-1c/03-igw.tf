# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "bos_igw01" {
  vpc_id = aws_vpc.bos_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}