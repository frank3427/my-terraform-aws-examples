%{ for eip in eips ~}
Host d28-inst${1+index(eips,eip)}
          Hostname ${lookup(eip,"public_ip")}
          User ${username}
          IdentityFile ${ssh_private_key_file}
          StrictHostKeyChecking no
%{ endfor ~}
