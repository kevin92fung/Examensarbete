# Longhorn
## Installera Longhorn med NFS-backup och statisk IP för UI-tjänsten

Denna guide beskriver hur du installerar Longhorn i en Kubernetes-miljö med Helm. Vi konfigurerar backup till en NFS-destination och sätter en statisk IP-adress för Longhorn UI-tjänsten.

---

## Förberedelser

1. **Se till att följande är klart:**
   - En Kubernetes-kluster är igång.
   - Helm är installerat och konfigurerat.
   - En NFS-server är tillgänglig med den angivna vägen (`NFS_PATH`) för backup.
   - En IP-adress (t.ex. `192.168.3.230`) är reserverad för Longhorn UI-tjänsten i nätverket.

---

## Installation av Longhorn med Helm

### 1. Exportera nödvändiga variabler
```bash
export REPLICA_COUNT=2
export NAS_IP=192.168.3.210
export NFS_PATH="/NAS/longhorn-Backup"
```

### 2. Lägg till Longhorn Helm-repo och uppdatera
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

### 3. Skapa namespace för Longhorn
```bash
kubectl create namespace longhorn-system
```

### 4. Installera Longhorn
Kör följande kommando för att installera Longhorn och konfigurera:
- Replikaantalet för volymer (`defaultClassReplicaCount`) till två.
- Backup-destinationen till NFS.
- Longhorn UI som LoadBalancer-tjänst.
- Återanvändning av lagring (`persistence.reclaimPolicy`) som `Retain`.

```bash
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system \
--set persistence.defaultDiskSelector.enable=true \
--set persistence.defaultClassReplicaCount=$REPLICA_COUNT \
--set service.ui.type=LoadBalancer \
--set defaultSettings.backupTarget="nfs://$NAS_IP:$NFS_PATH" \
--set persistence.reclaimPolicy=Retain
```

---

## Konfigurera Longhorn UI-tjänsten med statisk IP

### 1. Redigera LoadBalancer-tjänsten
Öppna tjänstkonfigurationen för Longhorn UI i en textredigerare:
```bash
EDITOR=nano kubectl edit service -n longhorn-system longhorn-frontend
```

### 2. Lägg till följande rader
Under `spec` lägger du till raden `loadBalancerIP` och konfigurerar `status` för att matcha den statiska IP-adressen:

```yaml
spec:
  allocateLoadBalancerNodePorts: true
  clusterIP: 10.43.11.175
  clusterIPs:
  - 10.43.11.175
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  loadBalancerIP: 192.168.3.230 #lägg till denna rad
  ports:
  - name: http
    nodePort: 30635
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: longhorn-ui
  sessionAffinity: None
  type: LoadBalancer
status:
  loadBalancer: #lägg till denna del
    ingress:
    - ip: 192.168.3.230
      ipMode: VIP
      ports:
      - port: 80
        protocol: TCP
```

---

## Verifiera installationen

### 1. Kontrollera att Longhorn körs korrekt
```bash
kubectl get pods -n longhorn-system
```

Alla pods ska vara i status `Running`.

### 2. Kontrollera Longhorn UI
Öppna webbläsaren och navigera till `http://192.168.3.230` för att komma åt Longhorn UI.

---

## Felsökning

- **Problem med NFS-backup?** Kontrollera att NFS-servern är igång och att åtkomstbehörigheter är korrekta.
- **Longhorn UI fungerar inte?** Kontrollera att IP-adressen för `loadBalancerIP` inte används av någon annan tjänst.

---

[⬆️ Till toppen](#top)



# Skript
```bash	
#!/bin/bash
export REPLICA_COUNT=2
export NAS_IP=192.168.3.210
export NFS_PATH="/NAS/longhorn-Backup"

helm repo add longhorn https://charts.longhorn.io
helm repo update
kubectl create namespace longhorn-system

helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system \
--set persistence.defaultDiskSelector.enable=true \
--set persistence.defaultClassReplicaCount=$REPLICA_COUNT \
--set service.ui.type=LoadBalancer \
--set defaultSettings.backupTarget="nfs://$NAS_IP:$NFS_PATH" \ 
--set persistence.reclaimPolicy=Retain

EDITOR=nano kubectl edit service -n longhorn-system longhorn-frontend
```