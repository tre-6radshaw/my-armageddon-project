# Explanation: gru is São Paulo’s Japanese town—local doctors, local compute, remote data.
resource "aws_ec2_transit_gateway" "gru_tgw01" {
  description = "gru-tgw01 (Sao Paulo spoke)"
  tags = { Name = "gru-tgw01" }
}

# Explanation: gru attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "gru_attach_sp_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.gru_tgw01.id
  vpc_id             = aws_vpc.gru_vpc01.id
  subnet_ids         = aws_subnet.gru_private_subnets[*].id
  tags = { Name = "gru-attach-sp-vpc01" }
}

# ####
# data "terraform_remote_state" "edo" {
#   backend = "s3"
#   config = {
#     bucket = "arma-japan-backend-lt1"
#     key    = "01.27.26/terraform.tfstate"
#     region = "ap-northeast-1"
#   }
# }

# # Explanation: gru accepts the corridor from edo—permissions are explicit, not assumed.
# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "gru_accept_peer01" {
#   transit_gateway_attachment_id  = data.terraform_remote_state.edo.outputs.edo_tgw_attachment.id
#   tags = { Name = "gru-accept-peer01" }
# }