#!/bin/bash
dnf update -y
dnf install -y python3-pip
dnf install -y mariadb105
pip3 install flask pymysql boto3

mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
import logging
from flask import Flask, request

# Setup logging
logging.basicConfig(
    filename='/opt/rdsapp/app.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(name)s %(threadName)s : %(message)s'
)
logger = logging.getLogger(__name__)

REGION = os.environ.get("AWS_REGION", "us-east-1")
SECRET_ID = os.environ.get("SECRET_ID", "bos/rds/mysql")
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    try:
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        s = json.loads(resp["SecretString"])
        return s
    except Exception as e:
        logger.error(f"Failed to retrieve secret {SECRET_ID}: {str(e)}")
        raise

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    db = c.get("dbname", "labdb")
    try:
        return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)
    except Exception as e:
        logger.error(f"DB connection failed: {str(e)}")
        raise

app = Flask(__name__)

@app.route("/")
def home():
    logger.info("Accessed home page")
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    logger.info("Initializing database")
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    try:
        conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
        cur.execute("USE labdb;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL
            );
        """)
        cur.close()
        conn.close()
        logger.info("Database and table initialized successfully")
        return "Initialized labdb + notes table."
    except Exception as e:
        logger.error(f"DB init failed: {str(e)}")
        return f"Initialization failed: {str(e)}", 500

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        logger.warning("Add note requested without 'note' parameter")
        return "Missing note param. Try: /add?note=hello", 400
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        logger.info(f"Inserted note: {note}")
        return f"Inserted note: {note}"
    except Exception as e:
        logger.error(f"Add note failed: {str(e)}")
        return f"Insert failed: {str(e)}", 500

@app.route("/list")
def list_notes():
    logger.info("Listing notes")
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        out = "<h3>Notes</h3><ul>"
        for r in rows:
            out += f"<li>{r[0]}: {r[1]}</li>"
        out += "</ul>"
        if not rows:
            out = "No notes yet."
            logger.info("No notes found")
        else:
            logger.info(f"Retrieved {len(rows)} notes")
        return out
    except Exception as e:
        logger.error(f"List notes failed: {str(e)}")
        return f"Cannot list notes: {str(e)}", 500

if __name__ == "__main__":
    logger.info("Starting Flask app")
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=bos/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

=== ADD CLOUDWATCH AGENT BELOW THIS LINE ===
# Install unified CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent-us-east-1/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create config directory if needed
mkdir -p /opt/aws/amazon-cloudwatch-agent/bin

cat >/opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
{
  "agent": {
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/rdsapp/*.log",
            "log_group_name": "/aws/ec2/bos-rds-app",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start the agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# Test log
logger "RDS App and CloudWatch Agent started successfully $(date)"