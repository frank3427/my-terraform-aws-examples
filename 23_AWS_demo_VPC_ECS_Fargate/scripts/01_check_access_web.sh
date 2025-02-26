#!/bin/bash

# update URL below before using the script
URL="http://demo23-alb-1343082884.eu-west-1.elb.amazonaws.com"

while true                                                                                                                                                          14:47:51
do
    printf "`date`: "
    curl -i $URL 2>&1 | grep "HTTP/"
    sleep 1
done
