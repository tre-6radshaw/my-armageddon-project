# Explanation: bos needs a hyperlane—this VPC is the Millennium Falcon’s flight corridor.
resource "aws_vpc" "bos_vpc01" {
  cidr_block           = "10.26.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}