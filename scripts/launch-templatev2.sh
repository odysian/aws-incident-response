#!/bin/bash
# === System update ===
yum update -y

# === Install required packages ===
yum install -y httpd php php-mysqli mariadb105 wget nmap-ncat

# === Start and enable Apache ===
systemctl start httpd
systemctl enable httpd

# === RDS connection info ===
RDS_ENDPOINT="database-cloudwatch-monitoring.c0fekuwkkx5w.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="odysbase69"
DB_NAME="webapp"

# === Wait for RDS to be reachable (with timeout) ===
MAX_ATTEMPTS=30
ATTEMPT=1
echo "Waiting for RDS to be available..." | tee -a /var/log/user-data.log
while ! mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; do
    echo "$(date): RDS not ready (attempt $ATTEMPT/$MAX_ATTEMPTS), sleeping 10s..." | tee -a /var/log/user-data.log
    ((ATTEMPT++))
    if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
        echo "$(date): ERROR - RDS not reachable after $MAX_ATTEMPTS attempts" | tee -a /var/log/user-data.log
        break
    fi
    sleep 10
done
echo "$(date): RDS check complete." | tee -a /var/log/user-data.log

# === Create a simple status page ===
cat > /var/www/html/index.php << EOF
<?php
\$host = "$RDS_ENDPOINT";
\$user = "$DB_USER";
\$pass = "$DB_PASS";
\$db   = "$DB_NAME";

\$conn = new mysqli(\$host, \$user, \$pass, \$db);

if (\$conn->connect_error) {
    http_response_code(500);
    die("Database connection failed: " . \$conn->connect_error);
}

echo "Status: OK\\n";
echo "Server: " . gethostname() . "\\n";
echo "Database: Connected\\n";
echo "Time: " . date('Y-m-d H:i:s') . "\\n";

\$conn->close();
?>
EOF

# === Create a lightweight health check page ===
cat > /var/www/html/healthcheck.php << EOF
<?php
\$host = "$RDS_ENDPOINT";
\$user = "$DB_USER";
\$pass = "$DB_PASS";
\$db   = "$DB_NAME";

\$conn = new mysqli(\$host, \$user, \$pass, \$db);

if (\$conn->connect_error) {
    http_response_code(503);
    die("UNHEALTHY: Database connection failed");
}

http_response_code(200);
echo "OK";

\$conn->close();
?>
EOF

# === Ensure log files exist before CloudWatch Agent starts ===
touch /var/log/httpd/access_log /var/log/httpd/error_log
chown apache:apache /var/log/httpd/*.log

# === Install CloudWatch Agent (prefers yum, fallback to manual rpm) ===
yum install -y amazon-cloudwatch-agent || (
  cd /tmp
  wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  rpm -U ./amazon-cloudwatch-agent.rpm
)

# === CloudWatch Agent config with ASG aggregation and root-only disk tracking ===
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}"
    },
    "aggregation_dimensions": [
      ["AutoScalingGroupName"]
    ],
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle","cpu_usage_iowait"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      },
      "net": {
        "measurement": ["bytes_sent","bytes_recv"],
        "resources": ["*"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webapp/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webapp/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# === Start and enable CloudWatch Agent ===
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

systemctl enable amazon-cloudwatch-agent

# === Set permissions and restart Apache ===
chown apache:apache /var/www/html/*.php
chmod 644 /var/www/html/*.php
systemctl restart httpd

# === Optional cleanup and log rotation ===
echo "0 4 * * * root find /tmp -type f -mtime +2 -delete" >> /etc/crontab

# === Completion Log ===
echo "----------------------------------------------" | tee -a /var/log/user-data.log
echo "$(date): User data script completed successfully." | tee -a /var/log/user-data.log
echo "----------------------------------------------" | tee -a /var/log/user-data.log
