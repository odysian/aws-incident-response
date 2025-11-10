# Curl loop to test load balancing traffic
for i in {1..5}; do
    curl webapp-alb-1270271488.us-east-1.elb.amazonaws.com/
    echo ""
done

# Test RDS connection
nc database-cloudwatch-monitoring.c0fekuwkkx5w.us-east-1.rds.amazonaws.com 3306

# Connect to MySQL
mysql -h database-cloudwatch-monitoring.c0fekuwkkx5w.us-east-1.rds.amazonaws.com -u admin -p

# Check apache logs
sudo tail -50 /var/log/httpd/error_log
