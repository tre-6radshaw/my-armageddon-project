# Explanation: edo Station is the hub—Tokyo is the data authority.
resource "aws_ec2_transit_gateway" "edo_tgw01" {
  description = "edo-tgw01 (Tokyo hub)"
  tags        = { Name = "edo-tgw01" }
}

# Explanation: edo connects to the Tokyo VPC—this is the gate to the medical records vault.
resource "aws_ec2_transit_gateway_vpc_attachment" "edo_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.edo_tgw01.id
  vpc_id             = aws_vpc.edo_vpc01.id
  subnet_ids         = aws_subnet.edo_private_subnets[*].id
  tags               = { Name = "edo-attach-tokyo-vpc01" }
}

# ###
# data "terraform_remote_state" "gru" {
#   backend = "s3"
#   config = {
#     bucket = "arma-brazil-backend-lt1"
#     key    = "01.27.26/terraform.tfstate"
#     region = "sa-east-1"
#   }
# }

# # Explanation: edo opens a corridor request to gru—compute may travel, data may not.
# resource "aws_ec2_transit_gateway_peering_attachment" "edo_to_gru_peer01" {
#   transit_gateway_id      = aws_ec2_transit_gateway.edo_tgw01.id
#   peer_region             = "sa-east-1"
#   peer_transit_gateway_id = data.terraform_remote_state.gru.outputs.gru_tgw01.id
#   tags = { Name = "edo-to-gru-peer01" }
# }

# output "edo_tgw_attachment" {
#   value = aws_ec2_transit_gateway_peering_attachment.edo_to_gru_peer01.id
# }