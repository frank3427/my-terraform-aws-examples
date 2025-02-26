#!/usr/bin/env python3
 
import socket
from datetime import datetime

host='xxx.rds.amazonaws.com'
port=3306
timeout_seconds=1
nb=5000

sum_latency_ms = 0.0
max_latency_ms = 0.0
min_latency_ms = 1000.0
for i in range(nb):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout_seconds)

    start_time = datetime.now()
    result = sock.connect_ex((host,int(port)))
    end_time = datetime.now()

    # if result == 0:
    #     print("Host: {}, Port: {} - True".format(host, port))
    # else:
    #     print("Host: {}, Port: {} - False".format(host, port))
    sock.close()

    duration = end_time - start_time
    latency_ms = duration.total_seconds()*1000
    print (f"{i} : Latency: {latency_ms:f} ms.") 

    sum_latency_ms += latency_ms
    if latency_ms > max_latency_ms:
        max_latency_ms = latency_ms
    if latency_ms < min_latency_ms:
        min_latency_ms = latency_ms

avg_latency_ms = sum_latency_ms / nb
print ("--------------")
print (f"Average Latency: {avg_latency_ms:f} ms.") 
print (f"Minimum Latency: {min_latency_ms:f} ms.") 
print (f"Maximum Latency: {max_latency_ms:f} ms.") 

