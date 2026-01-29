MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/cloud-config; charset="us-ascii"

packages:
 - amazon-efs-utils

runcmd:
 - mkdir -p ${param_efs_mntpt}
 - echo "${param_efs_fsid}:/ ${param_efs_mntpt} efs _netdev,tls,iam 0 0" >> /etc/fstab
 - mount -a -t efs defaults
 - chown ec2-user:ec2-user ${param_efs_mntpt}
 - amazon-linux-extras install -y lustre=latest
 - mkdir -p ${param_lustre_mntpt}
 - mount -t lustre ${param_lustre_dnsname}@tcp:/${param_lustre_mountname} ${param_lustre_mntpt}
 - chown ec2-user:ec2-user ${param_lustre_mntpt}

--==MYBOUNDARY==--