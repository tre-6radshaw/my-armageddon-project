# Welcome to Armageddon!

### Meeting 01-04-25
### Team Leader: Larry

Requirements:

Infrastructure
1. VPC name bos_vpc01
2. CIDR == 10.26.0.0/16
3. Public subnet == 10.26.1.0/24, 10.26.2.0/24
4. Private subnet == 10.26.101.0/24, 10.26.102.0/24
5. Region = US East 1
6. AZ == us-east-1a & us-east-1b

-    Security Group for RDS - ingress: mysql (3306) from EC2
-    Security Group for EC2 - ingress: HTTP(80) and SSH(22) from your ip(not anywhere)
-    Dont touch egress rules

### Meeting 01-06-26 Fixes:
-    Added personal AWS Account ID to .json policy
-    Received 'Internal Server Error' when trying to launch RDS app
     * Had too many digits in AWS ID in .json policy
-    When running cmd 6.1 - Switched default AWS region to us-east-1 via 'aws configure' command

### Screen Grabs
RDS-SG  
<img width="1918" height="736" alt="rds-sg" src="https://github.com/user-attachments/assets/e61de315-5f78-4a47-b4b1-7a733c2ba279" />

EC2-Instance  
<img width="781" height="359" alt="ec2-instance" src="https://github.com/user-attachments/assets/035a1b46-0f67-403b-bb72-aceab4bd7fca" />
    
EC2-Instance-Init  
<img width="589" height="261" alt="ec2-instance-init" src="https://github.com/user-attachments/assets/3a535c81-43d8-4862-9072-ac898ab08020" />

EC2-Notes  
<img width="651" height="301" alt="ec2-first-note" src="https://github.com/user-attachments/assets/8ff50fb7-944a-4d41-90bf-8a1779faf9eb" />  
<img width="722" height="304" alt="ec2-2nd-note" src="https://github.com/user-attachments/assets/ec8df86e-fa25-4956-9d63-5e4c7cec886c" />  
<img width="495" height="235" alt="ec2-3rd-note" src="https://github.com/user-attachments/assets/d8a88145-3f1e-45cd-a923-06a0bfa8083e" />  
<img width="450" height="310" alt="ec2-note-list" src="https://github.com/user-attachments/assets/143d1588-f369-4612-8dfc-5c4f257b6ba0" />  

Command 6.1
<img width="1116" height="298" alt="cmd6-1" src="https://github.com/user-attachments/assets/c3d3f676-2b48-4072-9e4d-3bed8f421150" />
    
Command 6.2
<img width="958" height="101" alt="cmd6-2" src="https://github.com/user-attachments/assets/b57a200c-937e-414d-ae91-a1da46b5123a" />

Command 6.3  
<img width="829" height="110" alt="cmd6-3" src="https://github.com/user-attachments/assets/68086f40-5de4-488f-ae8c-e4470df5ef70" />

Command 6.4  
<img width="752" height="160" alt="cmd6-4" src="https://github.com/user-attachments/assets/ad156e92-923d-4f1d-b31f-44e276a4da67" />

Command 6.5  
<img width="907" height="382" alt="cmd6-5" src="https://github.com/user-attachments/assets/4a516ade-10a4-46d5-b84f-e345c5c2298d" />

Command 6.6  
<img width="1614" height="454" alt="cmd6-6" src="https://github.com/user-attachments/assets/d74fc523-ca03-4e02-bd04-b7a752a4d6ca" />

Command 6.7  
<img width="921" height="406" alt="cmd6-7" src="https://github.com/user-attachments/assets/bf56db08-6fbb-4628-9eaf-76be48298932" />
