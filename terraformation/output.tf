output "db_addres" {
    description = "Id of the database"
    value       = "${aws_rds_cluster.main.endpoint}"
}