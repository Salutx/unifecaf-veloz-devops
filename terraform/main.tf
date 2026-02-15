terraform {
  required_version = ">= 1.6"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
  
  backend "gcs" {
    bucket = "loja-veloz-terraform-state"
    prefix = "prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "loja-veloz-gke"
  location = var.region
  
  # Versão do Kubernetes
  min_master_version = "1.28"
  
  # Remover default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Network
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Logging e Monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }
}

# Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  
  autoscaling {
    min_node_count = 3
    max_node_count = 10
  }
  
  node_config {
    preemptible  = false
    machine_type = "e2-standard-4"
    
    disk_size_gb = 50
    disk_type    = "pd-standard"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      environment = "production"
      app         = "loja-veloz"
    }
    
    tags = ["loja-veloz", "gke-node"]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "loja-veloz-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "loja-veloz-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "postgres" {
  name             = "loja-veloz-postgres"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier = "db-custom-2-7680"
    
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      point_in_time_recovery_enabled = true
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
    
    disk_autoresize = true
    disk_size       = 50
  }
  
  deletion_protection = true
}

resource "google_sql_database" "database" {
  name     = "lojaveloz"
  instance = google_sql_database_instance.postgres.name
}

# Outputs
output "kubernetes_cluster_name" {
  value = google_container_cluster.primary.name
}

output "kubernetes_cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}