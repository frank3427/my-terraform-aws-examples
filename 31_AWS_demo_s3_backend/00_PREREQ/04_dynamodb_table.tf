resource aws_dynamodb_table terraform-lock {
    name           = var.dynamodb_tab
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        "Name" = "demo31: DynamoDB Terraform State Lock Table"
    }
}