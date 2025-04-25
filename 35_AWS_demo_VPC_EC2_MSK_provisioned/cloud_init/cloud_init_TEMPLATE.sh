#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install and Configure Kafka client"
yum install java-11 -y 
wget https://archive.apache.org/dist/kafka/${param_kafka_version}/kafka_2.13-${param_kafka_version}.tgz -O /tmp/kafka.tgz
tar -xzf /tmp/kafka.tgz -C /opt/
cd /opt/kafka_2.13-${param_kafka_version}/libs
wget https://github.com/aws/aws-msk-iam-auth/releases/download/v1.1.1/aws-msk-iam-auth-1.1.1-all.jar

cat > /opt/kafka_2.13-${param_kafka_version}/bin/client.properties << EOF
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOF

echo "========== Create Kafka scripts"
cat > /home/ec2-user/01_create_kafka_topic.sh << EOF
TOPIC_NAME=MSKTutorialTopic
NB_PARTITIONS=3

KAFKA_DIR=/opt/kafka_2.13-${param_kafka_version}
BOOTSTRAP_SERVERS=${param_bootstrap_servers}
BOOTSTRAP_SERVER1=\$(echo \$BOOTSTRAP_SERVERS | cut -d',' -f1)

\$KAFKA_DIR/bin/kafka-topics.sh \\
  --create \\
  --bootstrap-server \$BOOTSTRAP_SERVER1 \\
  --command-config \$KAFKA_DIR/bin/client.properties \\
  --replication-factor 3 \\
  --partitions \$NB_PARTITIONS \\
  --topic \$TOPIC_NAME
EOF

cat > /home/ec2-user/02_kafka_producer.sh << EOF
TOPIC_NAME=MSKTutorialTopic

KAFKA_DIR=/opt/kafka_2.13-${param_kafka_version}
BOOTSTRAP_SERVERS=${param_bootstrap_servers}
BOOTSTRAP_SERVER1=\$(echo \$BOOTSTRAP_SERVERS | cut -d',' -f1)

\$KAFKA_DIR/bin/kafka-console-producer.sh \\
  --create \\
  --broker-list \$BOOTSTRAP_SERVER1 \\
  --producer.config \$KAFKA_DIR/bin/client.properties \\
  --topic \$TOPIC_NAME
EOF

cat > /home/ec2-user/03_kafka_consumer.sh << EOF
TOPIC_NAME=MSKTutorialTopic

KAFKA_DIR=/opt/kafka_2.13-${param_kafka_version}
BOOTSTRAP_SERVERS=${param_bootstrap_servers}
BOOTSTRAP_SERVER1=\$(echo \$BOOTSTRAP_SERVERS | cut -d',' -f1)

\$KAFKA_DIR/bin/kafka-console-consumer.sh \\
  --create \\
  --broker-list \$BOOTSTRAP_SERVER1 \\
  --consumer.config \$KAFKA_DIR/bin/client.properties \\
  --topic \$TOPIC_NAME \\
  --from-beginning
EOF

chmod +x /home/ec2-user/0*.sh
chown ec2-user:ec2-user /home/ec2-user/0*.sh

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot