
variable "clustername_in_the_ecs" {
  description = "name for the cluster in the ecr"
  type        = string  
  default     = "medusa_prod_cluster" 
}
variable "medusa_container_name" {
  description = "name for the medusa in the container"
  type        = string  
  default     = "nagaraju7876482/medusa-backend-prod:attempt34"
}
variable "postgres_container_name" {
  description = "name for the medusa in the container"
  type        = string  
  default     = "postgres:13"
}
variable "region_to_create_infrastructure" {
  description = "name for the medusa in the container"
  type        = string  
  default     = "us-east-1"
}



