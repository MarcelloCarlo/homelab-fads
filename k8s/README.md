# Kubernetes Manifests for Homelab Services

This directory contains Kubernetes manifests converted from Docker Compose files. All services are deployed in the `homelab` namespace.

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured to access your cluster
- Storage class configured for PersistentVolumeClaims
- Access to container registries (Docker Hub, Oracle Container Registry, etc.)

## Important Notes

### Before Deployment

1. **Create Secrets**: 
   - Copy `secrets.env.example` to `secrets.env`:
     ```bash
     cp secrets.env.example secrets.env
     ```
   - Edit `secrets.env` and fill in your actual passwords
   - **Important**: `secrets.env` is already in `.gitignore` - never commit it to git!
   - Create Kubernetes secrets using one of the helper scripts:
     - **Linux/Mac**: `./create-secrets.sh`
     - **Windows PowerShell**: `.\create-secrets.ps1`
   
   Alternatively, you can manually create secrets using `kubectl`:
   ```bash
   kubectl create secret generic pihole-secret \
     --from-literal=FTLCONF_webserver_api_password="your_password" \
     -n homelab
   ```

2. **Storage**: Ensure your cluster has a default StorageClass configured, or update the PVCs to use a specific StorageClass.

3. **Host Paths**: Some services require host paths:
   - **Diun & Portainer**: Access to `/var/run/docker.sock` (requires Docker socket)
   - **XP-VM**: Access to `/dev/kvm` and `/dev/net/tun` (requires KVM support)
   - **Jellyfin**: Access to `/home/BahayFiles` (update path if different)

4. **Privileged Containers**: Some services require privileged access:
   - Portainer (privileged: true)
   - XP-VM (privileged: true, hostNetwork: true)
   - Pi-hole (hostNetwork: true for macvlan-like functionality)

5. **Oracle Database**: Requires authentication to Oracle Container Registry. You'll need to create an image pull secret:
   ```bash
   kubectl create secret docker-registry oracle-registry-secret \
     --docker-server=container-registry.oracle.com \
     --docker-username=<your-username> \
     --docker-password=<your-password> \
     --docker-email=<your-email> \
     -n homelab
   ```
   Then add `imagePullSecrets` to the oraclesql deployment.

## Deployment Order

1. **Create secrets** (using the helper script):
   ```bash
   # Linux/Mac
   ./create-secrets.sh
   
   # Windows PowerShell
   .\create-secrets.ps1
   ```

2. **Create namespace**:
   ```bash
   kubectl apply -f 00-namespace.yaml
   ```

3. **Deploy services** (in any order, but databases first is recommended):
   ```bash
   kubectl apply -f mssql.yaml
   kubectl apply -f mysql.yaml
   kubectl apply -f pgsql.yaml
   kubectl apply -f oraclesql.yaml
   kubectl apply -f pihole.yaml
   kubectl apply -f portainer.yaml
   kubectl apply -f portainer-agent.yaml
   kubectl apply -f diun.yaml
   kubectl apply -f reverse-proxy-homelab-essentials.yaml
   kubectl apply -f xp-vm.yaml
   ```

   Or deploy all at once:
   ```bash
   kubectl apply -f .
   ```

## Service Ports

### NodePort Services

| Service | Port | NodePort | Description |
|---------|------|----------|-------------|
| Portainer | 8000 | 30800 | HTTP |
| Portainer | 9443 | 30943 | HTTPS |
| Portainer Agent | 9001 | 30090 | Agent |
| Pi-hole | 53 | 30053 | DNS (TCP/UDP) |
| Pi-hole | 80 | 30080 | HTTP |
| Pi-hole | 443 | 30443 | HTTPS |
| MSSQL | 1433 | 31433 | SQL Server |
| MySQL | 3306 | 30306 | MySQL |
| PostgreSQL | 5432 | 30433 | PostgreSQL |
| Adminer | 8080 | 30808 | Database Admin UI |
| Oracle SQL | 1521 | 31521 | Oracle Database |
| Oracle SQL | 5500 | 30550 | Oracle EM |
| Nginx Proxy Manager | 80 | 30080 | HTTP |
| Nginx Proxy Manager | 81 | 30081 | Admin UI |
| Nginx Proxy Manager | 443 | 30443 | HTTPS |
| XP-VM | 8006 | 30006 | Web UI |
| XP-VM | 3390 | 30390 | RDP (TCP/UDP) |

### ClusterIP Services

- **Nextcloud**: Port 80 (use Ingress or port-forward)
- **Home Assistant**: Port 8123 (use Ingress or port-forward)
- **Jellyfin**: Port 8096 (use Ingress or port-forward)

## Accessing Services

### Using NodePort
Access services via `<node-ip>:<nodePort>`

### Using Port Forward
```bash
# Nextcloud
kubectl port-forward -n homelab svc/nextcloud 8080:80

# Home Assistant
kubectl port-forward -n homelab svc/homeassistant 8123:8123

# Jellyfin
kubectl port-forward -n homelab svc/jellyfin 8096:8096
```

### Using Ingress
Configure an Ingress resource to route traffic to ClusterIP services. Nginx Proxy Manager can be used as an Ingress controller.

## Special Considerations

### Pi-hole
- Uses `hostNetwork: true` to bind directly to host ports
- May conflict with other services using ports 53, 80, 443
- Consider using a DaemonSet if you need it on all nodes

### Portainer & Diun
- Require access to Docker socket (`/var/run/docker.sock`)
- Only works if Docker is running on the Kubernetes nodes
- Consider using containerd socket instead for containerd-based clusters

### XP-VM
- Requires KVM support on the host
- Uses privileged mode and hostNetwork
- Needs `/dev/kvm` and `/dev/net/tun` devices
- May not work in all Kubernetes environments (works best on bare metal)

### Databases
- All databases use PersistentVolumeClaims for data persistence
- Ensure backups are configured
- Consider using StatefulSets for production deployments

## Troubleshooting

1. **Check pod status**:
   ```bash
   kubectl get pods -n homelab
   ```

2. **View pod logs**:
   ```bash
   kubectl logs -n homelab <pod-name>
   ```

3. **Check PVCs**:
   ```bash
   kubectl get pvc -n homelab
   ```

4. **Describe resources**:
   ```bash
   kubectl describe pod -n homelab <pod-name>
   kubectl describe pvc -n homelab <pvc-name>
   ```

## Cleanup

To remove all resources:
```bash
kubectl delete namespace homelab
```

**Warning**: This will delete all data in PersistentVolumeClaims. Ensure you have backups before deleting.
