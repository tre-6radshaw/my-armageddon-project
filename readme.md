# Welcome to Armageddon!

### Lab 1a
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
---
### Infrastructure Proof

RDS-SG inbound rule displaying ec2-sg:   
<img width="1916" height="872" alt="rds-sg" src="https://github.com/user-attachments/assets/5dbdb4c6-fcb1-4d66-a250-5bec662c04cf" />

EC2 Instance successfully operating over HTTP:  
<img width="1002" height="458" alt="ec2-http" src="https://github.com/user-attachments/assets/07a2b5fe-4e3d-4144-baa5-af1c91d7675f" />  

IAM Role Attached to EC2 Instance:
<img width="1332" height="880" alt="iam-role-ec2" src="https://github.com/user-attachments/assets/c6cdbb5a-df67-4077-a493-731e81dc5a37" />

---
### Application Proof

Running http://'ec2-public-ip'/init:  
<img width="1048" height="331" alt="ec2-http-init" src="https://github.com/user-attachments/assets/d3452fbe-ec64-41d0-bc89-a98d27119b66" />

Running http://'ec2-public-ip'/add?note=my-first-note:
<img width="867" height="417" alt="ec2-http-first-note" src="https://github.com/user-attachments/assets/858a90d5-615a-42a2-a92e-2d2124feb470" />  

2nd note:  
<img width="765" height="351" alt="ec2-http-second-note" src="https://github.com/user-attachments/assets/bcc849fd-3e1a-4517-8326-2ca3093043f2" />  

3rd note:
<img width="760" height="368" alt="ec2-http-third-note" src="https://github.com/user-attachments/assets/7aedb1d4-3756-41fa-bfa4-52c089c08ac4" />  

List:
<img width="762" height="333" alt="ec2-http-list" src="https://github.com/user-attachments/assets/497e4464-0915-420c-8f56-1f52c7fe0bda" />

---
RDS Endpoint:
<img width="688" height="332" alt="rds-endpoint" src="https://github.com/user-attachments/assets/614d5370-4a5f-411a-b5ee-fca28d1a233a" />

---
### Evidence for Audits
See output for command:  
'aws ec2 describe-security-groups --group-ids sg-'my-sg-group' > sg.json'  
[sg.json](https://github.com/user-attachments/files/24484929/sg.json)
<img width="900" height="121" alt="sg-json" src="https://github.com/user-attachments/assets/8178b9b2-9377-4a3c-820c-8e6917543507" />

See output for command:  
'aws rds describe-db-instances --db-instance-identifier bos-rds01 > rds.json'  
[rds.json](https://github.com/user-attachments/files/24485003/rds.json)
<img width="835" height="61" alt="rds-json" src="https://github.com/user-attachments/assets/02098142-0dbb-457d-9f08-355893e54e70" />

See output for command:  
'aws secretsmanager get-secret-value --secret-id bos/rds/mysql'  
[secret.json](https://github.com/user-attachments/files/24485116/secret.json)
<img width="880" height="141" alt="secret-json" src="https://github.com/user-attachments/assets/2a3b3d82-dc45-448a-8bf2-ad134c6284e7" />

See output for command:  
'aws ec2 describe-instances --instance-ids i-02dbc4c0286bc3fd7 > instance.json'
[instance.json](https://github.com/user-attachments/files/24485145/instance.json)
<img width="931" height="75" alt="instance-json" src="https://github.com/user-attachments/assets/32c01573-b26b-4073-8bf4-b9a1b4625e68" />

See output for command:  
'aws iam list-attached-role-policies --role-name bos-ec2-role01 > role-policies.json'  
[role-policies.json](https://github.com/user-attachments/files/24485192/role-policies.json)
<img width="867" height="72" alt="role-policies-json" src="https://github.com/user-attachments/assets/d51d6de4-ef6e-48af-b975-939fc989ddaf" />

---
