resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.namespace
  }
}

# Ingress NGINX
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = var.namespace

  # В v3 — это АРГУМЕНТ (list of objects), не блок:
  set = [
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    }
  ]
}

# PostgreSQL
resource "kubernetes_secret" "pg_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = var.namespace
  }
  data = {
    POSTGRES_PASSWORD = base64encode(var.postgres_password)
  }
  type = "Opaque"
}

resource "kubernetes_config_map" "pg_init" {
  metadata {
    name      = "postgres-init-sql"
    namespace = var.namespace
  }
  data = {
    "init.sql" = file("${path.module}/../sql/init.sql")
  }
}

resource "kubernetes_persistent_volume_claim" "pg_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = var.namespace
  }
  # ← ДОБАВЬ: не ждать Bound, пусть биндится, когда появится Pod
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"

    resources {
      requests = { storage = "2Gi" }
    }
  }
}

resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
    labels    = { app = "postgres" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "postgres" }
    }
    template {
      metadata {
        labels = { app = "postgres" }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:16"

          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgres_db
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.pg_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql/data"
          }
          volume_mount {
            name       = "init"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "pgdata"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pg_pvc.metadata[0].name
          }
        }
        volume {
          name = "init"
          config_map {
            name = kubernetes_config_map.pg_init.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
  }
  spec {
    selector = { app = "postgres" }
    port {
      name        = "pg"
      port        = 5432
      target_port = 5432
    }
  }
}

# OpenLDAP
resource "kubernetes_deployment" "openldap" {
  metadata {
    name      = "openldap"
    namespace = var.namespace
    labels    = { app = "openldap" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "openldap" }
    }
    template {
      metadata {
        labels = { app = "openldap" }
      }
      spec {
        container {
          name  = "openldap"
          image = "osixia/openldap:1.5.0"

          port {
            container_port = 389
          }

          env {
            name  = "LDAP_ORGANISATION"
            value = "NPV Org"
          }
          env {
            name  = "LDAP_DOMAIN"
            value = "example.org"
          }
          env {
            name  = "LDAP_ADMIN_PASSWORD"
            value = var.ldap_admin_password
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "openldap" {
  metadata {
    name      = "openldap"
    namespace = var.namespace
  }
  spec {
    selector = { app = "openldap" }
    port {
      name        = "ldap"
      port        = 389
      target_port = 389
    }
  }
}

# phpLDAPadmin
resource "kubernetes_deployment" "phpldapadmin" {
  metadata {
    name      = "phpldapadmin"
    namespace = var.namespace
    labels    = { app = "phpldapadmin" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "phpldapadmin" }
    }
    template {
      metadata {
        labels = { app = "phpldapadmin" }
      }
      spec {
        container {
          name  = "phpldapadmin"
          image = "osixia/phpldapadmin:0.9.0"

          port {
            container_port = 80
          }

          env {
            name  = "PHPLDAPADMIN_HTTPS"
            value = "false"
          }
          env {
            name  = "PHPLDAPADMIN_LDAP_HOSTS"
            value = "openldap"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "phpldapadmin" {
  metadata {
    name      = "phpldapadmin"
    namespace = var.namespace
  }
  spec {
    selector = { app = "phpldapadmin" }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "phpldapadmin" {
  metadata {
    name      = "phpldapadmin"
    namespace = var.namespace
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.ingress_ldapadmin_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.phpldapadmin.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.ingress_nginx]
}

# NPV-CALC App (2 replicas)
resource "kubernetes_deployment_v1" "npvcalc" {
  metadata {
    name      = "npv-calc"
    namespace = var.namespace
    labels    = { app = "npv-calc" }
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "npv-calc" }
    }
    template {
      metadata {
        labels = { app = "npv-calc" }
      }
      spec {
        container {
          name  = "npv-calc"
          image = "npv-calc:0.1.0"

          env {
            name  = "DB_HOST"
            value = kubernetes_service_v1.postgres.metadata[0].name
          }
          env {
            name  = "DB_PORT"
            value = "5432"
          }
          env {
            name  = "DB_NAME"
            value = var.postgres_db
          }
          env {
            name  = "DB_USER"
            value = var.postgres_user
          }
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.pg_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "LDAP_URL"
            value = "ldap://${kubernetes_service.openldap.metadata[0].name}:389"
          }
          env {
            name  = "LDAP_BASE"
            value = "dc=example,dc=org"
          }
          env {
            name  = "LDAP_USER_DN_PATTERN"
            value = "uid={0},ou=people,dc=example,dc=org"
          }
          env {
            name  = "LDAP_MANAGER_DN"
            value = "cn=admin,dc=example,dc=org"
          }
          env {
            name  = "LDAP_MANAGER_PASSWORD"
            value = var.ldap_admin_password
          }

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 20
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service_v1.postgres,
    kubernetes_service.openldap
  ]
}

resource "kubernetes_service_v1" "npvcalc" {
  metadata {
    name      = "npv-calc"
    namespace = var.namespace
  }
  spec {
    selector = { app = "npv-calc" }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "npv" {
  metadata {
    name      = "npv"
    namespace = var.namespace
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.ingress_npv_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.npvcalc.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.ingress_nginx]
}
