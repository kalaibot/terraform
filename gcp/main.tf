terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.41.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.11.0"
    }
  }
  backend "gcs" {
    credentials = "dummy-playground-xxxxxxx.json"
  }
}

# provider "vault" {
#   skip_child_token = true
# }

locals {
  gcp_auth_file = "dummy-playground-xxxxxxxx.json"
}

provider "google" {
  project = "dummy-playground"
  region  = "us-west2"
  zone    = "us-west2-a"
  credentials = file(local.gcp_auth_file)
}

resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "e2-medium"
  zone         = "us-west2-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

