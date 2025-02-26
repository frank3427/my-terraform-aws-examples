#!/bin/bash

CLUSTER="demo23-cluster"
SERVICE="demo23-svc2"
REGION="eu-west-1"
SCRIPT="./AWS_actions_ECS_tasks.py"
SCRIPT2=`basename $SCRIPT`

# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

NO_COLOR='\033[0m' # No Color
COLOR_TITLE='\033[1;31m'
COLOR_SCRIPT='\033[1;33m'

# ---------------------------- list ECS tasks
echo -e "${COLOR_TITLE}========== Listing ECS tasks${NO_COLOR}"
echo -e "${COLOR_SCRIPT}$SCRIPT2 list-tasks -r $REGION -c $CLUSTER${NO_COLOR}"
$SCRIPT list-tasks -r $REGION -c $CLUSTER

# ---------------------------- Remove subnets in 1 AZ from ECS service
echo
echo -e "${COLOR_TITLE}========== Remove subnets in 1 AZ from ECS service${NO_COLOR}"

while True
do
    printf "Enter AZ (a, b or c): "
    read AZ
    if [ "$AZ" == "a" ] || [ "$AZ" == "b" ] || [ "$AZ" == "c" ]; then break; fi
done
echo -e "${COLOR_SCRIPT}$SCRIPT2 remove-subnets -r $REGION -c $CLUSTER -s $SERVICE -az ${AZ} ${NO_COLOR}"
$SCRIPT remove-subnets -r $REGION -c $CLUSTER -s $SERVICE -az ${AZ}

# ---------------------------- list ECS tasks
echo
echo -e "${COLOR_TITLE}========== Listing ECS tasks${NO_COLOR}"
while True
do
    sleep 2
    echo -e "${COLOR_SCRIPT}`date`: $SCRIPT2 list-tasks -r $REGION -c $CLUSTER${NO_COLOR}"
    $SCRIPT list-tasks -r $REGION -c $CLUSTER
    echo
done
