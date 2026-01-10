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


* From within python folder:
    * run 'chmod +x ./gate_secrets_and_role.sh'
    * run 'chmod +x ./gate_network_db.sh'
    * run 'chmod +x ./run_all_gates.sh'

Next: run 'REGION=us-east-1 INSTANCE_ID=i-0123456789abcdef0 SECRET_ID=my-db-secret ./gate_secrets_and_role.sh'
    * then 'REGION=us-east-1 INSTANCE_ID=i-02c3c992f563e021a DB_ID=bos-rds01 ./gate_network_db.sh'
    * then 'REGION=us-east-1 INSTANCE_ID=i-02c3c992f563e021a SECRET_ID=bos/rds/mysql DB_ID=bos-rds01 ./run_all_gates.sh'
Instance Id: i-02c3c992f563e021a

Secrets name: bos/rds/mysql

DB-Identifier: bos-rds01

Confirm your email is in the variables file for sns_endpoint in order to direct your pager


### Breaking the Infrastructure

Take your EC2 public IP and make it into a viewable page via http://<instance IP>/init to view the database

Head to AWS Secrets Manager > Secrets in AWS Console
* Retrieve secrets value
* Change DB password (simple modification like adding a character)
    * DB should now deny login

SNS Alert Channel SNS Topic Name: lab-db-incidents aws sns create-topic --name lab-db-incidents Email Subscription (PagerDuty Simulation)

    >>>aws sns subscribe \
    --topic-arn <TOPIC_ARN> \
    --protocol email \
    --notification-endpoint youremail@example.com
    *  change email

    To retrieve your ARN:
    console > SNS > Topic > copy ARN
    my personal:
    arn:aws:sns:us-east-1:435830281557:bos-db-incidents

    To configure error alerts to your provided email:

    aws cloudwatch put-metric-alarm \
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
   * input your namespace: in this case 'bos'
   * Input your sns topic ARN: arn:aws:sns:us-east-1:435830281557:bos-db-incidents

>>> Alternate command: 
    aws cloudwatch put-metric-data \
    --namespace Lab/RDSApp \
    --metric-name DBConnectionErrors \
    --value 5 \
    --unit Count