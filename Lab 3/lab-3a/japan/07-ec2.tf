# # EC2
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

# # resource "aws_instance" "bos_ec201" {
# #   ami                    = var.ec2_ami_id
# #   instance_type          = var.ec2_instance_type
# #   subnet_id              = aws_subnet.bos_public_subnets[0].id
# #   vpc_security_group_ids = [aws_security_group.bos_ec2_sg01.id]
# #   iam_instance_profile   = aws_iam_instance_profile.bos_instance_profile01.name

# #   # TODO: student supplies user_data to install app + CW agent + configure log shipping

# #   tags = {
# #     Name = "${local.name_prefix}-ec201"
# #   }

# #   user_data = file("96-1a_user_data.sh")
# # }

# ############################################
# # Move EC2 into PRIVATE subnet (no public IP)
# ############################################

# # Explanation: edo hates exposure—private subnets keep your compute off the public holonet.
# resource "aws_instance" "edo_ec201_private_bonus" {
#   ami                   = var.ec2_ami_id
#   instance_type          = var.ec2_instance_type
#   subnet_id              = aws_subnet.edo_private_subnets[0].id
#   vpc_security_group_ids = [aws_security_group.edo_ec2_sg01.id]
#   iam_instance_profile   = aws_iam_instance_profile.edo_instance_profile01.name
#   user_data              = file("96-1a_user_data.sh")

#   # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
#   # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.

#   tags = {
#     Name = "${local.edo_prefix}-ec201-private"
#   }
# }