TASK_ID="04f76fab1c8c4bd79fb0ca989c79c51a"
aws ecs stop-task --cluster demo23-cluster --task $TASK_ID --reason "testing resiliency"