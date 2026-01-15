# Welcome to Armageddon!

### Lab 1b
### Meeting 01-10-25
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


---

Goal for 1b: After infrastructure has been properly built, let's break it and figure out the issue.

---
### New File Additions:
From Larry's Repo:  
* Download the lambda_ir_reporter.zip into your terraform file directory
    * Leave it as .zip file
* Create a lambda_ir_reporter directory
    * Include handler.py file
* Add the lambda folder and two files contained within
    * claude.py
    * handler.py
* Update the 1a_user_data.sh script with Larry's updated version
    * Includes the cloudwatch agent
* Add bedrock_autoreport.tf
    * Amazon Bedrock | AIOps Automated Incident Report Generation
* Add cloudwatch.tf file from Larry's repo
* In output.tf file:
    * Verify last 2 output blocks are active and not in comment format
* Add sns_topic.tf from Larry's repo
* Add python folder
    * include files within


From within python folder run the following, one at a time, in the following order to turn these bash scripts into executable files:

    >>> 'chmod +x ./gate_secrets_and_role.sh'
    >>> 'chmod +x ./gate_network_db.sh'
    >>> 'chmod +x ./run_all_gates.sh'  
    
<img width="877" height="205" alt="apply_permissions" src="https://github.com/user-attachments/assets/2a3b6180-7a3f-457b-a664-f8077b0d23bb" />

Next, run the following, one at a time, in the following order:

    >>> 'REGION=us-east-1 INSTANCE_ID=i-0123456789abcdef0 SECRET_ID=my-db-secret ./gate_secrets_and_role.sh'
    >>> 'REGION=us-east-1 INSTANCE_ID=i-02c3c992f563e021a DB_ID=bos-rds01 ./gate_network_db.sh'
    >>> 'REGION=us-east-1 INSTANCE_ID=i-02c3c992f563e021a SECRET_ID=bos/rds/mysql DB_ID=bos-rds01 ./run_all_gates.sh'
<img width="1303" height="492" alt="gate-secrets-role-test" src="https://github.com/user-attachments/assets/a20a9f40-c33b-48a2-9c89-668cd4a85f90" />  

<img width="941" height="467" alt="gate-network-db-test" src="https://github.com/user-attachments/assets/262fbb31-415d-4a33-a71a-4ce113c4c6a2" />  

<img width="1151" height="991" alt="run-all-test" src="https://github.com/user-attachments/assets/4bd34d18-0da4-46a8-871f-f0975b4b9b2e" />  


  *   Confirm your email is in the variables file for sns_endpoint in order to direct your pager


## Breaking the Infrastructure

Take your EC2 public IP and make it into a viewable page via http://<instance IP>/init to view the database

Head to AWS Console > AWS Secrets Manager > Secrets  
* Retrieve secrets value
* Change DB password (simple modification like adding a character)
    * DB should now deny login

<img width="1126" height="196" alt="db-error" src="https://github.com/user-attachments/assets/0e1ba92c-9d4e-4ecc-8c92-8349940823cc" />


### SNS Alert Channel  
SNS Topic Name: lab-db-incidents: 

    >>>  aws sns create-topic \
    --name lab-db-incidents
    
### Email Subscription (PagerDuty Simulation)

    >>> aws sns subscribe \
    --topic-arn <TOPIC_ARN> \
    --protocol email \
    --notification-endpoint youremail@example.com
    
    * change email to your desired email

<img width="1221" height="132" alt="sns-confirmation" src="https://github.com/user-attachments/assets/e7967279-f687-459f-9b0b-632d627d7b53" />  

<img width="1731" height="768" alt="sns-email-confirm" src="https://github.com/user-attachments/assets/15bdea6c-08fe-4665-b4bd-dda16d2ff3ee" />

### To retrieve your ARN:

    console > SNS > Topic > copy ARN
    my personal:
    arn:aws:sns:us-east-1:435830281557:bos-db-incidents

### To configure error alerts to your provided email:

    >>> aws cloudwatch put-metric-alarm \
    --alarm-name lab-db-connection-failure \
    --metric-name DBConnectionErrors \
    --namespace Lab/RDSApp \
    --statistic Sum \
    --period 300 \
    --threshold 3 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions <SNS_TOPIC_ARN>

    Be sure to:
    * input your namespace: in this case 'bos' or 'bos-rds01'
    * Input your sns topic ARN: arn:aws:sns:us-east-1:435830281557:bos-db-incidents

    >>> Alternate command: 
    aws cloudwatch put-metric-data \
    --namespace Lab/RDSApp \
    --metric-name DBConnectionErrors \
    --value 5 \
    --unit Count


<img width="1890" height="1131" alt="cloudwatch-error-notif" src="https://github.com/user-attachments/assets/15bc3fe3-8c9c-49ac-b4c7-e331cef26939" />  

<img width="1918" height="1033" alt="in-alarm" src="https://github.com/user-attachments/assets/3f09a6f3-db72-4e77-92bf-3fa7cfe9d991" />  

### Checking Application Logs:
For Windows Git Bash users, you may need to prefix this command and others with the environment variable below, as gitbash may misinterpret the path and output an error:

    MSYS_NO_PATHCONV=1
See:

    >>> aws logs filter-log-events \
    --log-group-name /aws/ec2/lab-rds-app \
    --filter-pattern "ERROR"
    
    (replacing 'lab' with 'bos')

    MSYS_NO_PATHCONV=1 aws logs filter-log-events --log-group-name /aws/ec2/bos-rds-app --filter-pattern "ERROR"


### Getting AWS SSM parameters:

    >>>  aws ssm get-parameters \
        --names /lab/db/endpoint /lab/db/port /lab/db/name \
        --with-decryption
    
    (replacing 'lab' with 'bos')

    -or-

    $ MSYS_NO_PATHCONV=1 aws ssm get-parameters --names /bos/db/endpoint /bos/db/port /bos/db/name --with-decryption

<img width="1823" height="640" alt="ssm-parameters" src="https://github.com/user-attachments/assets/4db3a62e-fd45-491d-ac38-31212cc6a613" />


### Retrieving Secrets Manager values:

    >>> aws secretsmanager get-secret-value --secret-id bos/rds/mysql

At this point, you should notice the DB password has been changed when you compare it to the known-good state.
Update Secrets Manager to known good state.

### Verify Recovery via curl command:

    >>> curl http://<instanceIP>/init



You should see as output:

    >>> Initialized labdb + notes table.
    
<img width="867" height="56" alt="curl-db" src="https://github.com/user-attachments/assets/cb7e86a9-da1b-4771-b642-5531e91d8887" />

### Confirm Alarm Clears

    Run:

    >>> aws cloudwatch put-metric-alarm \
    --alarm-name bos-db-connection-success \
    --metric-name DBConnectionErrors \
    --namespace Bos/RDSApp \
    --statistic Sum \
    --period 300 \
    --threshold 3 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --treat-missing-data notBreaching \
    --alarm-actions <SNS_TOPIC_ARN>

    (add your SNS Topic ARN)

    Wait about 5 mins, then run:

    >>> aws cloudwatch describe-alarms \
      --alarm-name lab-db-connection-success \
      --query "MetricAlarms[].StateValue"
     
<img width="1242" height="102" alt="alarm-ok" src="https://github.com/user-attachments/assets/04baaebe-c2f7-4c3b-8451-75089ffc3f6f" />  

    For the purposes of this lab, the alarm was manually set to OK since it was stuck on 'INSUFFICIENT DATA':

    >>> aws cloudwatch set-alarm-state --alarm-name bos-db-connection-failure --state-value OK --state-reason "Manually set to OK for lab testing - no real issues"


### Confirm Logs Normalize

    >>> MSYS_NO_PATHCONV=1 aws logs filter-log-events --log-group-name /aws/ec2/bos-rds-app --filter-pattern "ERROR"

<img width="1708" height="873" alt="logs-normalize" src="https://github.com/user-attachments/assets/e2c63bf2-0aba-4fd9-a601-0f2e9bc15160" />
