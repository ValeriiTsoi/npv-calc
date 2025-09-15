
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-npv"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "k3d-npv"
  }
}