%{ for public_ip in public_ip_nodes ~}
Host d45a-node${1+index(public_ip_nodes,public_ip)}
          Hostname ${public_ip}
          User ${username}
          IdentityFile ${ssh_private_key_file_nodes}
          StrictHostKeyChecking no
%{ endfor ~}