output information {
    value =<<EOF
RedShift cluster: 
    Endpoint: ${aws_redshift_cluster.demo36.endpoint}
    JDBC URL: ${aws_redshift_cluster.demo36.id}
    ODBC URL: ${aws_redshift_cluster.demo36.id}
EOF
}