Welcome to Armageddon!

First Meeting
01-04-25
Team Leader: Larry

Requirements:

infrastructure
1. VPC name bos_vpc01
2. CIDR == 10.26.0.0/16
3. Public subnet == 10.26.1.0/24, 10.26.2.0/24
4. Private subnet == 10.26.101.0/24, 10.26.102.0/24
5. Region = US East 1
6. AZ == us-east-1a & us-east-1b

Security Group for RDS - ingress: mysql (3306) from EC2
Security Group for EC2 - ingress: HTTP(80) and SSH(22) from your ip(not anywhere)
Dont touch egress rules

6-Jan-26 Fixes:
    Add personal AWS Account ID to .json policy