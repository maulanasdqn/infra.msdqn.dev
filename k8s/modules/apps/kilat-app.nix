# Kilat App - Nix-native Kubernetes deployment using nix-csi
#
# This deploys kilat-server and kilat-ui using nix-csi CSI driver
# which mounts the Nix store directly into pods - no container images needed.
{ lib, pkgs, kilat-app, targetSystem, ... }:
let
  labels = {
    "app.kubernetes.io/name" = "kilat";
    "app.kubernetes.io/managed-by" = "easykubenix";
  };

  # Get store paths from flake packages - these update automatically on rebuild
  # Use unsafeDiscardStringContext to allow evaluation without local build
  # (the actual packages will be built on the target system)
  kilatServerPkg = kilat-app.packages.${targetSystem}.kilat-server;
  kilatUiPkg = kilat-app.packages.${targetSystem}.kilat-ui or kilat-app.packages.${targetSystem}.default;

  # Convert to strings without build dependency
  kilatServer = builtins.unsafeDiscardStringContext (toString kilatServerPkg);
  kilatUi = builtins.unsafeDiscardStringContext (toString kilatUiPkg);
in
{
  kubernetes.resources.apps = {
    # Kilat Server (API) Deployment
    Deployment.kilat-server = {
      metadata.labels = labels // { "app.kubernetes.io/component" = "api"; };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "kilat-server";
        template = {
          metadata.labels = {
            app = "kilat-server";
          } // labels;
          spec = {
            # Use host network to access localhost PostgreSQL and MinIO
            hostNetwork = true;
            dnsPolicy = "ClusterFirstWithHostNet";
            containers = [
              {
                name = "kilat-server";
                image = "scratch";
                imagePullPolicy = "Never";
                # Dynamic store path from flake - evaluates to /nix/store/xxx/bin/kilat-server
                command = [ "${kilatServer}/bin/kilat-server" ];
                ports = [{ containerPort = 8082; name = "http"; protocol = "TCP"; }];
                env = [
                  # SSL certificates (required for OAuth, external API calls)
                  { name = "SSL_CERT_FILE"; value = "/etc/ssl/certs/ca-certificates.crt"; }
                  # Database
                  { name = "DATABASE_URL"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "database-url"; }; }
                  # Server
                  { name = "HOST"; value = "0.0.0.0"; }
                  { name = "PORT"; value = "8082"; }
                  { name = "RUST_LOG"; value = "info"; }
                  # MinIO
                  { name = "MINIO_ENDPOINT"; value = "http://127.0.0.1:9000"; }
                  { name = "MINIO_BUCKET"; value = "kilat-media"; }
                  { name = "MINIO_REGION"; value = "us-east-1"; }
                  { name = "MINIO_PUBLIC_URL"; value = "https://storage.kilat.app/kilat-media"; }
                  { name = "MINIO_ACCESS_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "minio-access-key"; }; }
                  { name = "MINIO_SECRET_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "minio-secret-key"; }; }
                  # Auth
                  { name = "JWT_SECRET"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "jwt-secret"; }; }
                  { name = "GOOGLE_CLIENT_ID"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "google-client-id"; }; }
                  { name = "GOOGLE_CLIENT_SECRET"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "google-client-secret"; }; }
                  { name = "GOOGLE_REDIRECT_URI"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "google-redirect-uri"; }; }
                  # AI/API Keys
                  { name = "FAL_API_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "fal-api-key"; }; }
                  { name = "OPENROUTER_API_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "openrouter-api-key"; }; }
                  { name = "BYTEPLUS_API_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "byteplus-api-key"; }; }
                  { name = "ELEVENLABS_API_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "elevenlabs-api-key"; }; }
                  # Email
                  { name = "RESEND_API_KEY"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "resend-api-key"; }; }
                  { name = "EMAIL_FROM"; valueFrom.secretKeyRef = { name = "kilat-secrets"; key = "email-from"; }; }
                ];
                volumeMounts = [
                  { name = "nix"; mountPath = "/nix"; readOnly = true; }
                  { name = "ssl-certs"; mountPath = "/etc/ssl/certs"; readOnly = true; }
                ];
                resources = {
                  requests = { memory = "128Mi"; cpu = "100m"; };
                  limits = { memory = "512Mi"; cpu = "500m"; };
                };
                livenessProbe = {
                  httpGet = { path = "/health"; port = 8082; };
                  initialDelaySeconds = 10;
                  periodSeconds = 30;
                };
                readinessProbe = {
                  httpGet = { path = "/health"; port = 8082; };
                  initialDelaySeconds = 5;
                  periodSeconds = 10;
                };
              }
            ];
            volumes = [
              {
                # Mount /nix via our custom CSI driver
                name = "nix";
                csi = {
                  driver = "nix.mount.csi";
                  readOnly = true;
                  # Optional: pass storePath for logging/debugging
                  volumeAttributes.storePath = "${kilatServer}";
                };
              }
              {
                # Mount host SSL certificates for OAuth and external API calls
                name = "ssl-certs";
                hostPath = {
                  path = "/etc/ssl/certs";
                  type = "Directory";
                };
              }
            ];
          };
        };
      };
    };

    # Kilat Server Service
    Service.kilat-server = {
      metadata.labels = labels // { "app.kubernetes.io/component" = "api"; };
      spec = {
        selector.app = "kilat-server";
        ports = [{ port = 8082; targetPort = 8082; protocol = "TCP"; name = "http"; }];
      };
    };

    # Kilat API Ingress
    Ingress.kilat-api = {
      metadata = {
        labels = labels // { "app.kubernetes.io/component" = "api"; };
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
          "nginx.ingress.kubernetes.io/proxy-body-size" = "100m";
          # Rate limiting
          "nginx.ingress.kubernetes.io/limit-rps" = "10";
          "nginx.ingress.kubernetes.io/limit-rpm" = "300";
          "nginx.ingress.kubernetes.io/limit-connections" = "20";
          "nginx.ingress.kubernetes.io/limit-burst-multiplier" = "5";
          # Security headers
          "nginx.ingress.kubernetes.io/configuration-snippet" = ''
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header Referrer-Policy "strict-origin-when-cross-origin" always;
          '';
        };
      };
      spec = {
        ingressClassName = "nginx";
        tls = [{ hosts = [ "api.kilat.app" ]; secretName = "kilat-api-tls"; }];
        rules = [{
          host = "api.kilat.app";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "kilat-server"; port.number = 8082; };
          }];
        }];
      };
    };

    # Kilat Frontend Deployment (static files via nginx)
    Deployment.kilat-frontend = {
      metadata.labels = labels // { "app.kubernetes.io/component" = "ui"; };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "kilat-frontend";
        template = {
          metadata.labels = { app = "kilat-frontend"; } // labels;
          spec = {
            containers = [
              {
                name = "nginx";
                image = "nginx:alpine";
                ports = [{ containerPort = 80; name = "http"; }];
                volumeMounts = [
                  { name = "nix"; mountPath = "/nix"; readOnly = true; }
                  { name = "nginx-config"; mountPath = "/etc/nginx/conf.d"; }
                ];
                resources = {
                  requests = { memory = "32Mi"; cpu = "10m"; };
                  limits = { memory = "128Mi"; cpu = "100m"; };
                };
              }
            ];
            volumes = [
              {
                name = "nix";
                csi = {
                  driver = "nix.mount.csi";
                  readOnly = true;
                  volumeAttributes.storePath = "${kilatUi}";
                };
              }
              { name = "nginx-config"; configMap.name = "kilat-frontend-nginx"; }
            ];
          };
        };
      };
    };

    # Nginx config for serving static frontend
    # Uses dynamic store path from flake evaluation
    ConfigMap.kilat-frontend-nginx = {
      metadata.labels = labels // { "app.kubernetes.io/component" = "ui"; };
      data."default.conf" = ''
        server {
          listen 80;
          server_name _;
          root ${kilatUi};
          index index.html;
          location / { try_files $uri $uri/ /index.html; }
          location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
          }
        }
      '';
    };

    # Kilat Frontend Service
    Service.kilat-frontend = {
      metadata.labels = labels // { "app.kubernetes.io/component" = "ui"; };
      spec = {
        selector.app = "kilat-frontend";
        ports = [{ port = 80; targetPort = 80; protocol = "TCP"; name = "http"; }];
      };
    };

    # Kilat Frontend Ingress
    Ingress.kilat-frontend = {
      metadata = {
        labels = labels // { "app.kubernetes.io/component" = "ui"; };
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
          # Rate limiting (higher for static frontend)
          "nginx.ingress.kubernetes.io/limit-rps" = "50";
          "nginx.ingress.kubernetes.io/limit-connections" = "30";
          "nginx.ingress.kubernetes.io/limit-burst-multiplier" = "10";
          # Security headers
          "nginx.ingress.kubernetes.io/configuration-snippet" = ''
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header Referrer-Policy "strict-origin-when-cross-origin" always;
          '';
        };
      };
      spec = {
        ingressClassName = "nginx";
        tls = [{ hosts = [ "kilat.app" ]; secretName = "kilat-frontend-tls"; }];
        rules = [{
          host = "kilat.app";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "kilat-frontend"; port.number = 80; };
          }];
        }];
      };
    };

    # Storage Ingress (MinIO)
    Ingress.kilat-storage = {
      metadata = {
        labels = labels // { "app.kubernetes.io/component" = "storage"; };
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
          "nginx.ingress.kubernetes.io/proxy-body-size" = "1g";
          # Rate limiting for uploads (stricter)
          "nginx.ingress.kubernetes.io/limit-rps" = "20";
          "nginx.ingress.kubernetes.io/limit-connections" = "10";
          "nginx.ingress.kubernetes.io/limit-burst-multiplier" = "3";
        };
      };
      spec = {
        ingressClassName = "nginx";
        tls = [{ hosts = [ "storage.kilat.app" ]; secretName = "kilat-storage-tls"; }];
        rules = [{
          host = "storage.kilat.app";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "minio"; port.number = 9000; };
          }];
        }];
      };
    };
  };
}
