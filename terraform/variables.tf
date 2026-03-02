variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devquiz"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "norwayeast"
}

variable "environment" {
  description = "Environment name (e.g. prod, dev)"
  type        = string
  default     = "prod"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret (minimum 32 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 32
    error_message = "jwt_secret must be at least 32 characters long."
  }
}

variable "admin_password" {
  description = "Admin password for the DevQuiz application"
  type        = string
  sensitive   = true
}

variable "ghcr_image" {
  description = "GitHub Container Registry image (without tag)"
  type        = string
  default     = "ghcr.io/mamk95/devquiz"
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "app_service_sku" {
  description = "App Service Plan SKU (must be Standard or higher for deployment slots)"
  type        = string
  default     = "S1"
}
