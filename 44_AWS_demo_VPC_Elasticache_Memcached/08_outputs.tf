# ------ Display the complete ssh command needed to connect to the instance
output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo44_inst1.public_ip}

---- You can then test connection to ElastiCache Memcached cluster wtih following command
telnet ${replace(aws_elasticache_cluster.memcached_cluster.configuration_endpoint,":"," ")}

---- Once connected, you can store and retrieve a key/value pair
set mykey 0 100 7
myvalue

get mykey

quit

Notes:
- 0 is the flags
- 100 is retention in seconds
- 7 is the number of characters in string "myvalue"

EOF
}