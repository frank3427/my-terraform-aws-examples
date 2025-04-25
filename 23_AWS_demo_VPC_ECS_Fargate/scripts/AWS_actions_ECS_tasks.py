#!/usr/bin/env python3

# --------------------------------------------------------------------------------------------------------------
# This script can:
#       1) list the ECS tasks inside an ECS cluster, possibly filtering by AZ or ECS service
#       2) kill the ECS tasks running in an ECS cluster and specified AZ, possibily filtering by ECS service
#       3) Remove subnet(s) in specified AZ from ECS service in an ECS cluster
#       4) Add subnet to ECS service in an ECS cluster (back to normal)
# 
# It can be used to simulate to loss of an AZ for an ECS cluster
#
# Author           : Christophe Pauliat 
# Tested Platforms : MacOS / Linux
# prerequisites    : AWS SDK for Python installed (pip install boto3)
#
# Versions
#    2024-03-27: Initial Version
#    2024-04-04: Add filter by ECS service name
#    2024-04-05: use subparsers in argparse
#    2024-04-17: Add option --remove-subnets to remove subnet(s) in specified AZ from ECS service
#    2024-04-17: Add option --add-subnet to add subnet to ECS service
#    2024-05-22: Fix issue in --remove-subnets (removal on public IP)
# --------------------------------------------------------------------------------------------------------------

# -------- import
import boto3
import sys
import json
import argparse
from tabulate import tabulate

# -------- functions
def get_ecs_tasks(cluster,service,region,az):
    # get the ECS tasks ARNs
    client_ecs = boto3.client('ecs', region_name=region)
    if service:
        response = client_ecs.list_tasks(cluster=cluster,serviceName=service)
    else:
        response = client_ecs.list_tasks(cluster=cluster)
    task_arns = response['taskArns']
    while 'nextToken' in response:
        if service:
            response = client_ecs.list_tasks(cluster=cluster,serviceName=service)
        else:
            response = client_ecs.list_tasks(cluster=cluster)
        task_arns.extend(response['taskArns'])

    # if no task found, return an empty list
    if task_arns == []:
        return []
        
    # get the ECS tasks details
    response = client_ecs.describe_tasks(cluster=cluster, tasks=task_arns)
    tasks = response['tasks']
           
    # if needed, filter by AZ
    if az:
        tasks2 = []
        for task in tasks:
            if task['availabilityZone'] == f"{region}{az}":
                tasks2.append(task)    # tasks.remove(task)
        tasks = tasks2

    return tasks

def display_ecs_tasks_csv(ecs_tasks,az):
    print("ECS Task ID, Name, Group, Status, AZ, Architecture, vCPU, Memory (GB), Subnet ID, Private IP address")
    for ecs_task in ecs_tasks:
        task_id = ecs_task['taskArn'].split('/')[-1]
        name    = ecs_task['containers'][0]['name']
        vcpu    = float(ecs_task['cpu']) / 1024
        memory  = ecs_task['memory']
        task_az = ecs_task['availabilityZone']
        status  = ecs_task['lastStatus']
        group   = ecs_task['group'] 
        arch    = ''
        for att in ecs_task['attributes']:
            if att['name'] == 'ecs.cpu-architecture':
                arch = att['value']
        subnet  = ''
        ip_v4   = ''
        for details in ecs_task['attachments'][0]['details']:
            if details['name'] == 'subnetId':
                subnet  = details['value']
            elif details['name'] == 'privateIPv4Address':
                ip_v4   = details['value']
        print(f"{task_id}, {name}, {group}, {status}, {task_az}, {arch}, {vcpu:0.1f}, {memory}, {subnet}, {ip_v4}")

def display_ecs_tasks_table(ecs_tasks):
    # sort tasks by AZ
    ecs_tasks.sort(key=lambda x: x['availabilityZone'])

    # display the ECS tasks table
    headers = ["ECS Task ID", "Name", "Group", "Status", "AZ", "Architecture", "vCPU", "Memory (GB)", "Subnet ID", "Private IP address"]
    data = []
    for ecs_task in ecs_tasks:
        task_id = ecs_task['taskArn'].split('/')[-1]
        name    = ecs_task['containers'][0]['name']
        vcpu    = float(ecs_task['cpu']) / 1024
        memory  = ecs_task['memory']
        task_az = ecs_task['availabilityZone']
        status  = ecs_task['lastStatus']
        group   = ecs_task['group'] 
        arch    = ''
        for att in ecs_task['attributes']:
            if att['name'] == 'ecs.cpu-architecture':
                arch = att['value']
        subnet  = ''
        ip_v4   = ''
        for details in ecs_task['attachments'][0]['details']:
            if details['name'] == 'subnetId':
                subnet  = details['value']
            elif details['name'] == 'privateIPv4Address':
                ip_v4   = details['value']
        data.append([task_id, name, group, status, task_az, arch, vcpu, memory, subnet, ip_v4])
    
    print (tabulate(data, headers))


def kill_ecs_tasks(cluster,region,ecs_tasks,az):
    # Ask for confirmation
    print ("Tasks found in this AZ:")
    display_ecs_tasks_table(ecs_tasks)
    print ()
    print ("Do you want to stop these ECS tasks ? (y/n): ",end="")
    choice = input()
    if choice != 'y':
        print ("Aborted")
        return

    # kill the ECS tasks
    print ()
    client_ecs = boto3.client('ecs', region_name=region)
    for ecs_task in ecs_tasks:
        response = client_ecs.stop_task(cluster=cluster, task=ecs_task['taskArn'])
        task_id  = ecs_task['taskArn'].split('/')[-1]
        print(f"Task stopped: {task_id}")

def remove_subnets_from_service(cluster, service, region, az):
    region_az = f"{region}{az}"

    # get all subnets in ECS service
    client_ecs = boto3.client('ecs', region_name=region)
    response = client_ecs.describe_services(cluster=cluster, services=[service])
    network_config     = response['services'][0]['networkConfiguration']
    service_subnet_ids = response['services'][0]['deployments'][0]['networkConfiguration']['awsvpcConfiguration']['subnets']
    
    # get the subnets to remove from the ECS service (in the specified AZ)
    client_ec2 = boto3.client('ec2', region_name=region)
    response = client_ec2.describe_subnets(Filters=[
        {
            'Name': 'availability-zone',
            'Values': [ region_az ]
        },
        ],SubnetIds=service_subnet_ids)
    subnet_ids_to_remove = [ sn['SubnetId'] for sn in response['Subnets'] ]

    # exit function if no subnet found
    if subnet_ids_to_remove == []:
        print (f"No subnet found for service {service} in AZ {region_az}")
        return
    
    # ask for confirmation
    print (f"Do you confirm removal of subnet(s) {subnet_ids_to_remove} from ECS service ? (y/n): ",end="")
    choice = input()
    if choice != 'y':
        print ("Aborted")
        return

    # remove the subnets in ECS service
    service_remaining_subnets = [sn for sn in service_subnet_ids if sn not in subnet_ids_to_remove]
    network_config['awsvpcConfiguration']['subnets'] = service_remaining_subnets
    print (f"Removing subnet(s) {subnet_ids_to_remove} from ECS service {service}")
    response = client_ecs.update_service(cluster=cluster, service=service, networkConfiguration=network_config)

def add_subnet_to_service(cluster, service, region, subnet_id):
    # client
    client_ecs = boto3.client('ecs', region_name=region)

    # get all subnets in ECS service
    response = client_ecs.describe_services(cluster=cluster, services=[service])
    service_subnets = response['services'][0]['deployments'][0]['networkConfiguration']['awsvpcConfiguration']['subnets']

    # add this subnet to ECS service
    service_subnets.append(subnet_id)
    print (f"Adding subnet {subnet_id} to ECS service {service}")
    response = client_ecs.update_service(cluster=cluster, service=service, networkConfiguration={'awsvpcConfiguration': {'subnets': service_subnets}})

def list_subnets_in_service(cluster, service, region):
    # client
    client_ecs = boto3.client('ecs', region_name=region)

    # get all subnets in ECS service
    response = client_ecs.describe_services(cluster=cluster, services=[service])
    service_subnets = response['services'][0]['deployments'][0]['networkConfiguration']['awsvpcConfiguration']['subnets']

    print('\n'.join(service_subnets))

# ---------- main
if __name__ == '__main__':

    # -- parse arguments
    parser     = argparse.ArgumentParser(description = "act on some ECS tasks")
    subparsers = parser.add_subparsers(dest='command')

    list = subparsers.add_parser('list-tasks', help='list ECS tasks')
    list.add_argument("-r",  "--region",       help="AWS region (example: eu-west-1)",required=True)
    list.add_argument("-c",  "--cluster",      help="ECS cluster name",required=True)
    list.add_argument("-s",  "--service",      help="ECS service name (optional filter)")
    list.add_argument("-az", "--az",           help="Availability Zone filter (optional, example: a, b or c)")

    kill = subparsers.add_parser('kill-tasks', help='kill ECS tasks')
    kill.add_argument("-r",  "--region",       help="AWS region (example: eu-west-1)",required=True)
    kill.add_argument("-c",  "--cluster",      help="ECS cluster name",required=True)
    kill.add_argument("-s",  "--service",      help="ECS service name (optional filter)")
    kill.add_argument("-az", "--az",           help="Availability Zone filter (optional, example: a, b or c)",required=True)

    rm_nets = subparsers.add_parser('remove-subnets', help='remove subnet(s) in specified AZ from ECS service')
    rm_nets.add_argument("-r",  "--region",    help="AWS region (example: eu-west-1)",required=True)
    rm_nets.add_argument("-c",  "--cluster",   help="ECS cluster name",required=True)
    rm_nets.add_argument("-s",  "--service",   help="ECS service name",required=True)
    rm_nets.add_argument("-az", "--az",        help="Availability Zone filter (optional, example: a, b or c)",required=True)

    add_net = subparsers.add_parser('add-subnet', help='add subnet to ECS service')
    add_net.add_argument("-r",  "--region",    help="AWS region (example: eu-west-1)",required=True)
    add_net.add_argument("-c",  "--cluster",   help="ECS cluster name",required=True)
    add_net.add_argument("-s",  "--service",   help="ECS service name",required=True)
    add_net.add_argument("-sn", "--subnet",    help="Subnet ID to be added to ECS service",required=True)

    list_nets = subparsers.add_parser('list-subnets', help='list subnets in ECS service')
    list_nets.add_argument("-r",  "--region",    help="AWS region (example: eu-west-1)",required=True)
    list_nets.add_argument("-c",  "--cluster",   help="ECS cluster name",required=True)
    list_nets.add_argument("-s",  "--service",   help="ECS service name",required=True)

    args = parser.parse_args()

    if args.command == "list-tasks":
        ecs_tasks = get_ecs_tasks(args.cluster, args.service, args.region, args.az)
        display_ecs_tasks_table(ecs_tasks)

    elif args.command == "kill-tasks":
        ecs_tasks = get_ecs_tasks(args.cluster, args.service, args.region, args.az)
        kill_ecs_tasks(args.cluster, args.region, ecs_tasks, args.az)

    elif args.command == "remove-subnets":
        remove_subnets_from_service(args.cluster, args.service, args.region, args.az)

    elif args.command == "add-subnet":
        add_subnet_to_service(args.cluster, args.service, args.region, args.subnet)

    elif args.command == "list-subnets":
        list_subnets_in_service(args.cluster, args.service, args.region)

    # -- happy end
    exit (0)
