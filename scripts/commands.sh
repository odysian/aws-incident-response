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

# Change instance setting to allow unlimited or standard bursting
aws ec2 modify-instance-credit-specification \
  --instance-credit-specifications InstanceId=i-0580dca4d1f9677db,CpuCredits=unlimited