# Installation av K3S High Availability med Kube-VIP och Longhorn

## Förberedelser

- **Root-åtkomst**: Allt görs som root.
- **Nodkrav**: 
  - 3 st VM/Raspberry Pi för master-noder.
  - Minst 2 st VM/Raspberry Pi för worker-noder.
- **IP-konfiguration**:
  - Reservera IP-adresser för klustret i din router: `192.168.xxx.200-254`.
  - Sätt fasta IP-adresser på alla noder.
- **Delad lagring**:
  - NAS med NFS-delning krävs.

### Sätt en fast IP-adress
Redigera nätverksinställningarna:
```bash
nano /etc/network/interfaces
```
Lägg till följande under `#The primary network interface`:
```bash
auto eth0
iface eth0 inet static
  address 192.168.xxx.xxx
  netmask 255.255.255.0
  gateway 192.168.xxx.1
  dns-nameservers 8.8.8.8 8.8.4.4
```

Starta om nätverket:
```bash
sudo systemctl restart networking
```

Bekräfta att IP-adressen är satt:
```bash
ip a
```

**Förklaring**: 
- En fast IP-adress behövs för att varje nod ska vara kontaktbar via en förutsägbar adress. Detta är särskilt viktigt för master-noder och virtuella IP-adresser som används av Kube-VIP.

**Bekräftelse**: 
- Kontrollera att rätt IP är konfigurerad genom att köra `ip a`. Adressen ska matcha den statiska konfigurationen.

---

## Installation av K3S Master-1

Installera K3S och nödvändiga tillägg:
```bash
apt install curl wget jq nfs-common -y
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
--cluster-init \
--tls-san=<Virtual-ip-loadbalancer> \
--disable=traefik \
--disable=servicelb \
--advertise-address=<Virtual-ip-loadbalancer> \
--node-taint CriticalAddonsOnly=true:NoExecute
```

**Förklaring**:
- K3S är en lättviktig Kubernetes-distribution som är optimerad för mindre resurser men behåller alla funktioner från Kubernetes.
- `--cluster-init`: Initierar det första klustret.
- `--tls-san`: Gör att servercertifikaten accepterar det virtuella IP-laddbalanserarens adress.
- `--disable=traefik`: Inaktiverar den inbyggda ingresskontrollern för att ge utrymme för andra lösningar som NGINX eller Longhorn.
- `--node-taint CriticalAddonsOnly=true:NoExecute`: Gör att bara kritiska tjänster körs på denna nod.

**Bekräftelse**:
- Kontrollera att K3S körs:
```bash
kubectl get nodes
```
- Master-noden bör visas som `Ready`.


## Installation av Kube-VIP på Master-1

**Förberedelser**: Byt ut `<IP som ska användas virtuellt för kontrollplanet>` och `<Namn på nätverkskort>` (t.ex. `eth0`).

1. Installera RBAC-regler för Kube-VIP:
```bash
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
```

2. Generera och tillämpa Kube-VIP-konfiguration:
```bash
export VIP=<IP som ska användas virtuellt för kontrollplanet>
export INTERFACE=<Namn på nätverkskort>
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection > kube-vip-manifest.yaml

kubectl apply -f kube-vip-manifest.yaml
```

**Förklaring**:
- **Kube-VIP** fungerar som en virtuell IP-laddbalanserare. Det skapar en HA-konfiguration för Kubernetes kontrollplan genom att dela en VIP mellan master-noderna.
- `--arp`: Används för ARP-baserad IP-delning, vilket är optimalt i små nätverk.

**Bekräftelse**:
- Kontrollera att Kube-VIP körs:
```bash
kubectl get pods -n kube-system | grep kube-vip
```
- Du bör se en `kube-vip`-pod som är `Running`.

3. Uppdatera serverns konfiguration för att använda Kube-VIP:
```bash
sed -i 's/127.0.0.1/'"$VIP"'/g' /etc/rancher/k3s/k3s.yaml
```

[⬆️ Till toppen](#top)

---
## Installation av K3S Master-2 och Master-3
1. Installera K3S på de andra master-noderna:

`Lägg till master-node i K3S och installera nödvändiga tillägg:`
```bash
apt install curl wget jq nfs-common -y
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
--tls-san=<Virtual-ip-loadbalancer> \
--disable=traefik \
--disable=servicelb \
--advertise-address=<Virtual-ip-loadbalancer> \
--node-taint CriticalAddonsOnly=true:NoExecute
```
**Bekräftelse**:
- Kontrollera att K3S körs:
```bash
kubectl get nodes
```
- Master-noden bör visas som `Ready`.
## Installation av Kube-VIP på Master-2 och Master-3

**Förberedelser**: Byt ut `<IP som ska användas virtuellt för kontrollplanet>` och `<Namn på nätverkskort>` (t.ex. `eth0`).

1. Installera RBAC-regler för Kube-VIP:
```bash
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
```

2. Generera och tillämpa Kube-VIP-konfiguration:
```bash
export VIP=<IP som ska användas virtuellt för kontrollplanet>
export INTERFACE=<Namn på nätverkskort>
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection > kube-vip-manifest.yaml

kubectl apply -f kube-vip-manifest.yaml
```

**Bekräftelse**:
- Kontrollera att Kube-VIP körs:
```bash
kubectl get pods -n kube-system | grep kube-vip
```
- Du bör se en `kube-vip`-pod som är `Running`.

3. Uppdatera serverns konfiguration för att använda Kube-VIP:
```bash
sed -i 's/127.0.0.1/'"$VIP"'/g' /etc/rancher/k3s/k3s.yaml
```

[⬆️ Till toppen](#top)

---
---

## Installation av K3S Worker-noder

1. Installera nödvändiga paket och iscsi-tjänster:
```bash
apt install curl wget jq nfs-common open-iscsi -y

systemctl enable iscsid
systemctl start iscsid
```

2. Lägg till worker-noder till klustret:
```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - agent \
    --server https://<VIP>:6443
```

**Förklaring**:
- Worker-noder hanterar applikationsarbetsbelastningar och kommunicerar med kontrollplanen via Kube-VIP.

**Bekräftelse**:
- Kontrollera att worker-noderna är tillagda:
```bash
kubectl get nodes
```
- De nya worker-noderna bör visas som `Ready`.

[⬆️ Till toppen](#top)

---

## Installera Longhorn

1. Installera Longhorn:
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/deploy/longhorn.yaml
```

2. Ställ in Longhorn som standardlagringsklass:
```bash
kubectl patch storageclass longhorn -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

3. Ändra Longhorn-frontend till LoadBalancer och använd en fast IP:
```bash
EDITOR=nano kubectl edit service -n longhorn-system longhorn-frontend
```
Ändra `spec.type` till `LoadBalancer` och lägg till `loadBalancerIP: <IP från pool>`.

`Exempel`:
```bash
spec:
  allocateLoadBalancerNodePorts: true
  clusterIP: 10.43.29.197
  clusterIPs:
  - 10.43.29.197
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  loadBalancerIP: 192.168.3.230
  ports:
  - name: http
    nodePort: 31010
    port: 80
    protocol: TCP
    targetPort: http
  selector:
    app: longhorn-ui
  sessionAffinity: None
  type: LoadBalancer
status:
  loadBalancer:
    ingress:
    - ip: 192.168.3.230
      ipMode: VIP
```

### Förklaring och Bekräftelse för Longhorn

**Förklaring**:  
- Longhorn är en distribuerad blocklagringslösning för Kubernetes som förenklar hantering av volymer och säkerställer replikering av data över flera noder.  
- En `LoadBalancer`-tjänst används för att göra Longhorns användargränssnitt åtkomligt via den virtuella IP-adressen som konfigurerats med Kube-VIP.  

**Bekräftelse**:  

1. **Kontrollera Longhorns pods**  
   För att verifiera att alla pods är igång, kör följande kommando:  
   ```bash
   kubectl get pods -n longhorn-system
   ```  
   Alla pods bör ha statusen `Running`.  

2. **Verifiera Longhorn-tjänster**  
   Kontrollera att tjänsterna är korrekt distribuerade:  
   ```bash
   kubectl get services -n longhorn-system
   ```  
   Du bör se något liknande detta:  
   ```
   NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)          AGE
   longhorn-backend       ClusterIP      10.43.27.131    <none>            9500/TCP         1m
   longhorn-frontend      LoadBalancer   10.43.29.197    <IP från pool>    80:31010/TCP    1m
   longhorn-instance-manager ClusterIP  10.43.33.219    <none>            8500/TCP         1m
   ```
   - **`longhorn-backend`**: Backend-tjänsten för Longhorn.  
   - **`longhorn-frontend`**: Webbgränssnittet för Longhorn. Här ska `EXTERNAL-IP` visa den virtuella IP-adressen från din Kube-VIP-konfiguration.  
   - **`longhorn-instance-manager`**: Hanterar instanser av lagring.  

3. **Verifiera Longhorn UI**  
   Navigera till den virtuella IP-adressen i din webbläsare för att öppna Longhorns användargränssnitt.  

4. **Felsökning vid saknad `EXTERNAL-IP`**  
   Om `EXTERNAL-IP` inte är satt för `longhorn-frontend`, dubbelkolla att:  
   - Kube-VIP-konfigurationen är korrekt.  
   - Den virtuella IP-adressen är tillgänglig och reserverad i din router.  

[⬆️ Till toppen](#top)  

### Konfigurera NAS som Backupmål för Longhorn

För att säkerställa dataskydd och återställningsmöjligheter kan du konfigurera en NAS (Network Attached Storage) som backupmål för Longhorn.

---

### Steg 1: Skapa en Backupmål-URL  
Backupmål i Longhorn definieras med hjälp av en URL. Om du använder en NAS via NFS, skapa en NFS-share och använd den som mål.  

Exempel på URL för en NFS-mapp:  
```
nfs://<IP-adress>/<delad-mapp>
```

---

### Steg 2: Konfigurera NAS i Longhorn  
1. **Öppna Longhorns Användargränssnitt**  
   Navigera till Longhorns UI via den virtuella IP-adressen (t.ex. `http://<EXTERNAL-IP>`).  

2. **Gå till Backup-inställningar**  
   - Klicka på **Settings** > **Backup Target**.  
   - Ange URL för din NFS-share, t.ex.:  
     ```
     nfs://192.168.1.100/longhorn-backup
     ```  
   - Lägg till eventuella autentiseringsuppgifter om de behövs.  

3. **Spara och Verifiera**  
   Klicka på **Save** och verifiera att backupmålet är tillgängligt.  

---

### Steg 3: Skapa och Återställa Backups  
1. **Skapa Backup**  
   - Gå till **Volumes** i Longhorn UI.  
   - Välj en volym och klicka på **Create Backup**.  
   - Kontrollera att backupen lyckas genom att navigera till **Backups**.  

2. **Återställ Backup**  
   - Gå till **Backups** och välj en befintlig backup.  
   - Klicka på **Restore** för att skapa en ny volym baserad på backupen.  

---

### Bekräftelse  

1. **Kontrollera Backup-inställningar**  
   Kör följande kommando för att verifiera inställningarna:  
   ```bash
   kubectl -n longhorn-system get settings backup-target
   ```  

2. **Verifiera NFS-anslutning**  
   Kontrollera att din NAS är åtkomlig från noderna:  
   ```bash
   showmount -e <NAS-IP>
   ```  
   Du bör se den delade mappen listad.  

3. **Testa backup och återställning**  
   Säkerställ att en backup kan skapas och återställas utan problem.  

[⬆️ Till toppen](#top)  