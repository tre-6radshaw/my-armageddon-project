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

RDS Instance in Same VPC:  
<img width="1318" height="938" alt="rds-in-vpc" src="https://github.com/user-attachments/assets/25ee8db4-473b-4a7b-be16-3b71b398cf15" />  

IAM Role Attached to EC2 Instance:
<img width="1332" height="880" alt="iam-role-ec2" src="https://github.com/user-attachments/assets/c6cdbb5a-df67-4077-a493-731e81dc5a37" />


---
### Application Proof
#### Successful DB initialization / Inserting & Reading records from RDS
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
### Verification Evidence
CLI output proving connectivity and configuration:  
<img width="688" height="332" alt="rds-endpoint" src="https://github.com/user-attachments/assets/614d5370-4a5f-411a-b5ee-fca28d1a233a" />  

Browser output showing DB data:  
Must connect via EC2 session manager, as DB is inaccessible from public internet
<img width="1137" height="747" alt="ec2-connect-db" src="https://github.com/user-attachments/assets/6fdb3fb2-e75b-41ee-9d95-8132191730ea" />

---
### Technical Verification Using AWS CLI (Mandatory)

6.1 - Verify EC2 Instance:  
* Command: aws ec2 describe-instances --filters "Name=tag:Name,Values=bos-ec201" --query "Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name}"
* Expected:
  * Instance ID returned  
  * Instance state = running  
<img width="1760" height="278" alt="verify-ec2-instance" src="https://github.com/user-attachments/assets/137b256d-cfa3-4d70-b28b-3ac75883a8d4" />  
 
*****

6.2 Verify IAM Role Attached to EC2
* Command: aws ec2 describe-instances --instance-ids <INSTANCE_ID> --query "Reservations[].Instances[].IamInstanceProfile.Arn"
* Expected:  
  * ARN of an IAM instance profile (not null)
<img width="1532" height="241" alt="iam-role-attached-to-ec2" src="https://github.com/user-attachments/assets/236eaf9d-b6ca-484b-ad0c-5769c20ab897" />

*****

6.3 Verify RDS Instance State
* Command: aws rds describe-db-instances --db-instance-identifier bos-rds01 --query "DBInstances[].DBInstanceStatus"
* Expected:
    * Available
<img width="1616" height="175" alt="rds-instance-state" src="https://github.com/user-attachments/assets/2072ba57-50f2-490e-b843-00cf246e7a05" />

*****

6.4 Verify RDS Endpoint (Connectivity Target)
* Command: aws rds describe-db-instances --db-instance-identifier bos-rds01 --query "DBInstances[].Endpoint"
* Expected
    * Endpoint Address
    * Port 3306
<img width="1412" height="256" alt="rds-endpoint-connectivity-target" src="https://github.com/user-attachments/assets/a1235342-7964-4bb7-a17e-a51371268e9c" />

*****

6.5 Verify Security Group Rules (Critical)
* Command: aws ec2 describe-security-groups --filters "Name=tag:Name,Values=bos-rds-sg01" --query "SecurityGroups[].IpPermissions"
* Expected
    * TCP port 3306
    * Source referencing EC2 security group ID, not CIDR
<img width="1611" height="515" alt="verify-security-group-rules" src="https://github.com/user-attachments/assets/67820177-2936-48a5-8d87-fc8ce4c1e7db" />

*****

6.6 Verify Secrets Manager Access (From EC2)
SSH into EC2 and run:
* Command: aws secretsmanager get-secret-value --secret-id bos/rds/mysql
* Expected
    * JSON Containing:
      * username
      * password
      * host
      * port
<img width="1915" height="503" alt="secrets-manager-access" src="https://github.com/user-attachments/assets/9ff89e09-c3b9-4aac-8a8c-682e3ece34a4" />

*****

6.7 Verify DB connectivity (From EC2)  
Install MySQL Client (temporary validation)  
* Had to install MariaDB
  * worked nonetheless
  * Successful login & no timeout or connection refused errors
<img width="1043" height="640" alt="verify-db-connectivity" src="https://github.com/user-attachments/assets/1dc97ec4-652a-4dba-bc7e-667054b9a55c" />

*****

6.8 Verify Data Path End-to-End  
From browser:  
http://<EC2_PUBLIC_IP>/init  
<img width="455" height="288" alt="6-8init" src="https://github.com/user-attachments/assets/40f264c2-bdc2-4d6f-9157-c69664823224" />  

http://<EC2_PUBLIC_IP>/add?note=cloud_labs_are_real  
<img width="712" height="281" alt="6-8cloudlabsreal" src="https://github.com/user-attachments/assets/a8b59e39-5f99-45c1-872c-2329d8985abd" />  

http://<EC2_PUBLIC_IP>/list  
<img width="467" height="348" alt="6 8list" src="https://github.com/user-attachments/assets/20d28cb1-e9af-4080-a70c-bcbe4ea6d4cd" />

---
### Short Answers:

A. Why is DB inbound source restricted to the EC2 security group?

We don't want our internal database with potentially sensitive information accessible to the public internet. This is a secure configuration that limits access.

B. What port does MySQL use?

Port 3306  

C. Why is Secrets Manager better than storing creds in code/user-data?

Secrets Manager is better than storing creds in code/user-data because Secrets Manager is a secure, centralized service with strong access controls and encryption that mitigates the potential for creds to be leaked.

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
