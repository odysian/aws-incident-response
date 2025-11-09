# Curl loop for traffic
for i in {1..30}; do
    curl webapp-alb-1270271488.us-east-1.elb.amazonaws.com/
    echo ""
done


# Connect to MySQL
mysql -h database-cloudwatch-monitoring.c0fekuwkkx5w.us-east-1.rds.amazonaws.com -u admin -p
