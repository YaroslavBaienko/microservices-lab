terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "myapp" {
  name = "myapp:latest"
  build {
    context = "."  # Correct argument for build directory
  }
}

resource "docker_container" "myapp_container" {
  image = docker_image.myapp.image_id  # Correct reference to built image ID
  name  = "myapp"
  ports {
    internal = 80
    external = 8000
  }
}
