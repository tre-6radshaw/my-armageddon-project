# IGW
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "edo_igw01" {
  vpc_id = aws_vpc.edo_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}