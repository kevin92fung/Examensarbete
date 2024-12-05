# Installation av Admin maskin
För att installera `kubectl` och konfigurera en kubeconfig-fil på din admin-maskin, kan du följa stegen nedan:

### 1. Installera `kubectl`:

Kör följande kommando för att installera `kubectl` på din admin-maskin:

```bash
apt install curl -y
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

Bekräfta att installationen lyckades genom att köra:
```bash
kubectl version --client
```
Detta kommer att visa versionen av `kubectl` som är installerad.

### 2. Skapa kubeconfig-fil för klustret:

På valfri master-nod i ditt k3s-kluster, hämta kubeconfig-filen:

```bash
cat /etc/rancher/k3s/k3s.yaml
```

Kopiera texten från filen. Nästa steg är att skapa en kubeconfig-fil på din admin-maskin.

### 3. Skapa och redigera kubeconfig-fil:

På din admin-maskin, skapa mappen för kubeconfig och redigera filen:

```bash
mkdir -p ~/.kube/
nano ~/.kube/config
chmod 600 ~/.kube/config
```

Klistra in den kopierade texten från kubeconfig-filen, och ändra `server`-fältet så att det pekar på din VIP (Virtuella IP). Här är ett exempel:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <certificate-authority-data>
    server: https://<VIP>:6443  # Ersätt <VIP> med den faktiska VIP-adressen
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: <client-certificate-data>
    client-key-data: <client-key-data>
```

Byt ut `<VIP>` med den faktiska IP-adressen för din k3s lastbalanserare (VIP). Spara och stäng filen.

### 4. Bekräfta konfiguration:

För att bekräfta att konfigurationen är korrekt och att `kubectl` kan kommunicera med klustret, kör följande kommando:

```bash
kubectl get nodes
```

---
# Installera Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```




# Longhorn
### Installation av Longhorn

Följ dessa steg för att installera Longhorn i ditt Kubernetes-kluster. Tänk på att ersätta de miljöspecifika variablerna, som `NAS_IP` och `MOUNT_PATH`, med värden som passar din miljö.

#### 1. Exportera miljövariabler

Innan installationen bör du sätta upp miljövariabler som refererar till din NAS-server och sökvägen där du vill lagra Longhorn-backuper. **Byt ut värdena nedan så att de passar din miljö.**

```bash
export NAS_IP="192.168.3.210"  # Byt ut med din NAS-server IP-adress
export MOUNT_PATH="/NAS/longhorn-Backup"  # Byt ut med den exakta sökvägen för lagring på din NAS
```

- **NAS_IP**: IP-adressen för din NAS-server.
- **MOUNT_PATH**: Den fullständiga sökvägen där Longhorn kommer att lagra backuper på din NAS.

#### 2. Lägg till Longhorn Helm repository

Lägg till Longhorn Helm repository och uppdatera Helm-repositoryt för att få tillgång till den senaste versionen av Longhorn.

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

#### 3. Skapa ett namespace för Longhorn

Skapa ett separat namespace för Longhorn-resurser så att de hålls isolerade från andra applikationer i ditt kluster.

```bash
kubectl create namespace longhorn-system
```

#### 4. Installera Longhorn via Helm

Installera Longhorn i det skapade `longhorn-system` namespace med följande konfiguration. **Byt ut variablerna så att de passar din miljö**, särskilt `backupTarget` för att använda rätt NFS-sökväg och din NAS IP.

```bash
helm install longhorn longhorn/longhorn --namespace longhorn-system \
  --set service.ui.type=LoadBalancer \
  --set persistence.defaultClassReplicaCount=2 \
  --set persistence.reclaimPolicy=Retain \
  --set defaultSettings.defaultReplicaCount=2 \
  --set defaultSettings.backupTarget="nfs://$NAS_IP:$MOUNT_PATH"
```

Förklaring av parametrarna:
- **service.ui.type=LoadBalancer**: Exponerar Longhorn UI som en LoadBalancer-tjänst för enkel åtkomst.
- **persistence.defaultClassReplicaCount=2**: Sätter antalet repliker för standardpersistenceklassen till 2 för hög tillgänglighet.
- **persistence.reclaimPolicy=Retain**: Sätter återvinningspolicyn till `Retain`, vilket innebär att när en persistent volym tas bort, behålls data.
- **defaultSettings.defaultReplicaCount=2**: Sätter antalet repliker för standardlagring till 2 för hög tillgänglighet.
- **defaultSettings.backupTarget="NFS:$NAS_IP:$MOUNT_PATH"**: Konfigurerar Longhorn att lagra backuper på din NFS-server (NAS) vid den angivna sökvägen.

#### 5. Uppdatera StorageClass

Uppdatera `local-path` StorageClass så att den inte är standard. Detta är viktigt för att säkerställa att Longhorn används som lagringslösning i stället för andra alternativ.

```bash
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### 6. Verifiera installationen

När installationen är klar kan du kontrollera att alla pods har startat korrekt genom att köra:

```bash
kubectl get pods -n longhorn-system
```

För att se om Longhorn UI är tillgängligt via LoadBalancer-tjänsten, använd följande kommando för att få information om tjänsterna i `longhorn-system` namespace:

```bash
kubectl get svc -n longhorn-system
```

Om du har konfigurerat LoadBalancer korrekt, bör du kunna nå Longhorn UI via den externa IP-adressen som tilldelats tjänsten. Gå till IP-adressen eller domännamnet som du har angett i din LoadBalancer-tjänst.

### Sammanfattning

Denna guide installerar Longhorn i ditt Kubernetes-kluster och konfigurerar det att använda din NAS-server för backup och persistenta volymer. Kom ihåg att **ersätta de miljöspecifika variablerna** som `NAS_IP` och `MOUNT_PATH` för att matcha din egen miljö, samt att säkerställa att din LoadBalancer är korrekt konfigurerad för att nå Longhorn UI.

















---

# Installera Rancher UI

### 1. Lägg till Rancher och cert-manager Helm-repositories

Först lägger vi till Helm-repositories för Rancher och cert-manager:

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### 2. Skapa namespace för Rancher

Skapa ett namespace för Rancher, där Rancher UI kommer att installeras:

```bash
kubectl create namespace cattle-system
```

### 3. Installera cert-manager

Cert-manager behövs för att hantera certifikat för Rancher. För att installera cert-manager, kör dessa kommandon:

1. Ladda ner och applicera cert-manager CRD (Custom Resource Definitions):

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.crds.yaml
```

2. Installera cert-manager via Helm:

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace
```

3. Verifiera att cert-manager har installerats och att poddarna körs:

```bash
kubectl get pods -n cert-manager
```

### 4. Installera Rancher UI

Nu kan vi installera Rancher UI. Ersätt `rancher.local` med din egen IP-adress eller domännamn.

1. Installera Rancher via Helm:

```bash
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.local \
  --set service.type=LoadBalancer
```

- `hostname`: Sätt detta till den IP-adress eller det domännamn du vill använda för att nå Rancher UI.
- `bootstrapPassword`: Sätt detta till ett säkert lösenord för att logga in första gången.
- `service.type=LoadBalancer`: Detta gör att Rancher exponeras som en LoadBalancer.

2. Verifiera att Rancher har rullats ut:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

Exempel på utdata:

```text
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
deployment "rancher" successfully rolled out
```

### 5. Verifiera installationen

Kolla statusen på poddarna för Rancher:

```bash
kubectl get pods -n cattle-system
```

### 6. Hämta Rancher UI IP från LoadBalancer

För att hämta den externa IP som LoadBalancer tilldelar Rancher UI, kör följande kommando:

```bash
kubectl get svc -n cattle-system
```

Detta kommando visar en lista över alla tjänster i `cattle-system` namespace. Leta efter raden där `NAME` är `rancher`, och kolla på kolumnen `EXTERNAL-IP`. Detta är den IP-adressen som LoadBalancer tilldelar Rancher UI.

Exempel på utdata:

```text
NAME          TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
rancher       LoadBalancer   10.43.23.102   192.168.3.220   80:30515/TCP     2m
```

I detta exempel är `192.168.3.220` den externa IP-adressen som LoadBalancer har tilldelat Rancher UI, och den kan användas för att komma åt Rancher-gränssnittet via webbläsaren.

### 7. Åtkomst till Rancher UI

När du har den externa IP-adressen från `kubectl get svc`, kan du öppna Rancher UI via webbläsaren på:

```text
http://192.168.3.220  # Byt ut med den IP som din LoadBalancer har tilldelat
```

### 8. Logga in på Rancher UI

När du har öppnat Rancher UI via webbläsaren, behöver du skapa ett lösenord för att kunna logga in. Följ dessa steg:

1. Kör kommandot för helminstallationen för att skapa ett lösenord för Rancher UI:
Detta kommando returnerar ett lösenord som du kan använda för att logga in första gången.

2. Kopiera lösenordet som genereras på admininstansen och klistra in det i Rancher UI som "Bootstrap Password".

3. När du loggar in första gången, ombeds du att skapa ett nytt lösenord för Rancher UI (minst 12 tecken).

4. Efter att du har skapat ett nytt lösenord, logga in med användarnamnet `admin` och det nya lösenordet.

