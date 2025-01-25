# Environment setting (e.g., development, production)
variable "environment" {
  description = "The environment in which the resources are being deployed (e.g., dev, prod)."
}

# Aws region for resource deployment
variable "region" {
  description = "The Aws region where the resources will be deployed."
}

# Aws region for resource deployment
variable "availability_zone" {
  description = "The Aws region where the resources will be deployed."
}

# Customer name
variable "customer_name" {
  description = "Customer name."
}

# Tags for resource organization and identification
variable "tags" {
  description = "Tags to assign to the resources for categorization and tracking."
  type        = map(string)
  default     = {}
}

# Aurora
variable "aurora_password" {
  description = "Password for Aurora"
}

# Fargate
variable "processor_image" {
  description = "Processor image for fargate"
}