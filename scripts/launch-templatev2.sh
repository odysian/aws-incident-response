#!/bin/bash
set +e  # Continue execution even if a command fails
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "----------------------------------------------"
echo "$(date): Starting user data script..."
echo "----------------------------------------------"

# === System update ===
echo "$(date): Updating system packages..."
yum update -y
if [ $? -ne 0 ]; then
  echo "$(date): WARNING - yum update failed"
fi

# === Install required packages ===
echo "$(date): Installing base packages..."
yum install -y httpd php php-mysqli mariadb105 wget nmap-ncat
if [ $? -ne 0 ]; then
  echo "$(date): ERROR - Failed to install packages (httpd/php/mariadb)."
else
  echo "$(date): Package installation succeeded."
fi

# === Start and enable Apache ===
systemctl start httpd
if [ $? -ne 0 ]; then
  echo "$(date): ERROR - Failed to start Apache"
else
  systemctl enable httpd
  echo "$(date): Apache started and enabled successfully."
fi

# === RDS connection info ===
RDS_ENDPOINT="<insert rds endpoint here>"
DB_USER="admin"
DB_PASS="password"
DB_NAME="<insert db name here>"

# === Wait for RDS to be reachable (with timeout) ===
MAX_ATTEMPTS=30
ATTEMPT=1
echo "$(date): Waiting for RDS to be available..."
while ! mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; do
    echo "$(date): RDS not ready (attempt $ATTEMPT/$MAX_ATTEMPTS), sleeping 10s..."
    ((ATTEMPT++))
    if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
        echo "$(date): ERROR - RDS not reachable after $MAX_ATTEMPTS attempts"
        break
    fi
    sleep 10
done
echo "$(date): RDS check complete."

# === Create web pages ===
mkdir -p /var/www/html
echo "$(date): Creating web pages..."
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

# === Prepare log files ===
touch /var/log/httpd/access_log /var/log/httpd/error_log
chown apache:apache /var/log/httpd/*.log

# === Install CloudWatch Agent ===
echo "$(date): Installing CloudWatch Agent..."
yum install -y amazon-cloudwatch-agent || (
  cd /tmp
  wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  rpm -U ./amazon-cloudwatch-agent.rpm
)
if [ $? -ne 0 ]; then
  echo "$(date): ERROR - Failed to install CloudWatch Agent."
else
  echo "$(date): CloudWatch Agent installed successfully."
fi

# === Write CW Agent config ===
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
    "aggregation_dimensions": [["AutoScalingGroupName"]],
    "metrics_collected": {
      "cpu": {"measurement": ["cpu_usage_idle","cpu_usage_iowait"], "metrics_collection_interval": 60},
      "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60},
      "disk": {"measurement": ["used_percent"], "metrics_collection_interval": 60, "resources": ["/"]},
      "net": {"measurement": ["bytes_sent","bytes_recv"], "resources": ["*"]}
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {"file_path": "/var/log/httpd/access_log","log_group_name":"/aws/ec2/webapp/access","log_stream_name":"{instance_id}"},
          {"file_path": "/var/log/httpd/error_log","log_group_name":"/aws/ec2/webapp/error","log_stream_name":"{instance_id}"}
        ]
      }
    }
  }
}
EOF

# === Start and enable CloudWatch Agent ===
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
if [ $? -ne 0 ]; then
  echo "$(date): ERROR - Failed to start CloudWatch Agent."
else
  systemctl enable amazon-cloudwatch-agent
  echo "$(date): CloudWatch Agent started successfully."
fi

# === Final web server setup ===
chown apache:apache /var/www/html/*.php
chmod 644 /var/www/html/*.php
systemctl restart httpd
if [ $? -ne 0 ]; then
  echo "$(date): ERROR - Apache restart failed"
else
  echo "$(date): Apache restarted successfully."
fi

# === Optional cleanup ===
echo "0 4 * * * root find /tmp -type f -mtime +2 -delete" >> /etc/crontab

# === Send bootstrap success metric ===
aws cloudwatch put-metric-data \
  --namespace "InstanceBootstrap" \
  --metric-name "UserDataSuccess" \
  --value 1 \
  --region us-east-1
if [ $? -eq 0 ]; then
  echo "$(date): Bootstrap success metric sent to CloudWatch."
else
  echo "$(date): WARNING - Failed to send CloudWatch metric."
fi

echo "----------------------------------------------"
echo "$(date): User data script completed successfully."
echo "----------------------------------------------"
