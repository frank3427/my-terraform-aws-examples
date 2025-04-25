AWSTemplateFormatVersion: '2010-09-09'
Description: 'Template for PCS Compute Environment and Queue'

Resources:
  ComputeNodeGroup:
    Type: AWS::PCS::ComputeNodeGroup
    Properties:
      Name: ${compute_node_group_name}
      ClusterId: ${pcs_cluster_id}
      ScalingConfiguration:
        MaxInstanceCount: ${nodes_count}
        MinInstanceCount: ${nodes_count}
      InstanceConfigs:
        - InstanceType: ${instance_type}
      CustomLaunchTemplate:
        Version: ${launch_template_version}
        Id: ${launch_template_id}
      SubnetIds:
        - ${subnet_id}
      IamInstanceProfileArn: ${instance_profile_arn}
  PCSQueue:
    Type: AWS::PCS::Queue
    Properties:
      Name: ${queue_name}
      ClusterId: ${pcs_cluster_id}
      ComputeNodeGroupConfigurations:
        - ComputeNodeGroupId: !GetAtt ComputeNodeGroup.Id

Outputs:
  ComputeNodeGroupID:
    Description: Compute Node Group ID
    Value: !GetAtt ComputeNodeGroup.Id  