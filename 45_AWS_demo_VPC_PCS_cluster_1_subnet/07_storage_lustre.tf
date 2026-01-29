resource aws_fsx_lustre_file_system demo45a_lustre {
  storage_capacity            = var.fsx_lustre_size_gb
  subnet_ids                  = [ aws_subnet.demo45a_public.id ]
  security_group_ids          = [ aws_security_group.demo45a.id ]
  deployment_type             = "PERSISTENT_2"
  data_compression_type       = "LZ4"
  per_unit_storage_throughput = 125
  file_system_type_version    = var.fsx_lustre_version
  tags                        = { Name = "demo45a-lustre-fs1" }
}