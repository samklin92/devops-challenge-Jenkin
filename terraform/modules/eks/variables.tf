variable "project_name"       { type = string }
variable "private_subnets"    { type = list(string) }
variable "node_instance_type" { type = string }
variable "node_min"           { type = number }
variable "node_max"           { type = number }
variable "node_desired"       { type = number }
