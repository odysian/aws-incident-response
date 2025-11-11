#!/bin/bash

for i in {1..25}; do
    curl webapp-alb-1270271488.us-east-1.elb.amazonaws.com/
    echo ""
done