# Kubernetes Manifests for Hostinger k3s Cluster

## Directory Structure

```
k8s/
├── namespaces/          # Namespace definitions
├── apps/                # Application deployments
│   ├── personal-website/
│   ├── rkm-backend/
│   ├── rkm-frontend/
│   └── ...
├── databases/           # Stateful services
│   ├── postgresql/
│   └── minio/
├── secrets/             # Encrypted secrets (sops)
└── monitoring/          # Monitoring stack
```

## Migration Waves

### Wave 1: Stateless Frontends
- personal-website
- rkm-frontend
- rkm-admin-frontend
- verychic-frontend

### Wave 2: Simple Containers
- uptime-kuma
- n8n

### Wave 3: Backend Services
- hpyd
- roasting-startup
- kilat-app
- rkm-backend

### Wave 4: Databases
- PostgreSQL
- MinIO

### Wave 5: Complex Stacks
- Glitchtip
- Roundcube

## Deployment Commands

```bash
# Apply namespaces first
kubectl apply -f namespaces/

# Deploy an app
kubectl apply -k apps/personal-website/

# Check deployment status
kubectl get pods -n apps
kubectl get ingress -n apps
```

## Secrets Management

Secrets are managed via sops-secrets-operator. Create SopsSecret CRDs:

```yaml
apiVersion: isindir.github.com/v1alpha3
kind: SopsSecret
metadata:
  name: personal-website-env
  namespace: apps
spec:
  secretTemplates:
    - name: personal-website-env
      stringData:
        ENV_VAR: ENC[AES256_GCM,...]
```

## SSL/TLS

SSL certificates are automatically provisioned by cert-manager using Let's Encrypt.
Use the `letsencrypt-prod` ClusterIssuer for production certificates.
