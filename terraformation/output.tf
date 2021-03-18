output "db_addres" {
    description = "Id of the database"
    value       = "${aws_rds_cluster.main.endpoint}"
}
output "db_password" {
    description = "Database Password"
    value       = "${local.master_password}"
}