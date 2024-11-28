# Guide för Installation av K3s med Virtuellt IP för Lastbalansering via Kube-VIP

Den här guiden går igenom installationen av **K3s** tillsammans med ett **virtuellt IP** för lastbalansering via **Kube-VIP**. 

Alla steg ska köras som root. Logga in som root med:

```bash
su -
```

## Steg 1: Uppdatera och Installera Nödvändiga Verktyg

Börja med att uppdatera systemet och installera de verktyg som krävs:

```bash
apt update && apt upgrade -y
apt install curl wget jq -y
```

## Steg 2: Installera K3s på Master-noden

Installera K3s på **Master-noden** genom att köra följande kommando:

```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
    --cluster-init \
    --tls-san=<Virtual-ip-loadbalancer> \
    --disable=traefik \
    --disable=servicelb \
    --node-taint CriticalAddonsOnly=true:NoExecute
```

- Byt ut `<Virtual-ip-loadbalancer>` med det virtuella IP som du vill använda för lastbalanseraren.

## Steg 3: Installera Kube-VIP

### Skapa mapp för Manifest och Ladda Ner RBAC Manifest

Skapa en mapp för manifest och ladda ner RBAC-manifestet:

```bash
mkdir -p /var/lib/rancher/k3s/server/manifests/
curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml
```

### Applicera RBAC Manifestet

Kör följande kommando för att tillämpa RBAC-manifestet på ditt K3s-kluster:

```bash
kubectl apply -f /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml
```

## Steg 4: Sätt VIP och Interface Variabler

Sätt de nödvändiga variablerna för VIP och nätverksinterface:

```bash
export VIP=<IP som ska användas virtuellt>
export INTERFACE=<Namn på nätverkskort, t.ex. eth0>
```

- Byt ut `<IP som ska användas virtuellt>` med det virtuella IP.
- Byt ut `<Namn på nätverkskort>` med ditt nätverkskort, exempelvis `eth0`.

## Steg 5: Ladda Ner den Senaste Versionen av Kube-VIP

Ladda ner den senaste versionen av **Kube-VIP** med följande kommando:

```bash
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
```

## Steg 6: Skapa Manifest för Kube-VIP

Skapa manifestet för Kube-VIP med följande kommando:

```bash
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
```

Detta kommando skapar en `kube-vip-manifest.yaml` som kan användas för att applicera Kube-VIP på ditt kluster.

## Steg 7: Applicera Manifestet

Applicera det skapade manifestet på ditt Kubernetes-kluster:

```bash
kubectl apply -f kube-vip-manifest.yaml
```

## Steg 8: Verifiera att Kube-VIP Körs

Kontrollera att Kube-VIP körs korrekt genom att köra följande kommandon:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=kube-vip-ds
kubectl get daemonsets --all-namespaces
```

Dessa kommandon visar om Kube-VIP är korrekt installerat och körs på dina noder.

## Steg 9: Lägg Till Worker-noder

För att lägga till **Worker-noder** i ditt K3s-kluster, använd token som finns på Master-noden:

1. Hitta tokenet på Master-noden:

   ```bash
   cat /var/lib/rancher/k3s/server/node-token
   ```
2. Installera Curl
   ```bash
   apt install curl -y
   ```

3. Använd tokenet för att ansluta en Worker-node:

   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://<Virtuellt-IP>:6443 K3S_TOKEN=<TOKEN-från-MASTER> sh -
   ```

Byt ut `<Virtuellt-IP>` med det virtuella IP och `<TOKEN-från-MASTER>` med tokenet du hämtade från Master-noden.

---

## Sammanfattning

Denna guide har gått igenom installationen av **K3s** och **Kube-VIP** för att konfigurera ett virtuellt IP för lastbalansering i ett K3s-kluster. Genom att följa stegen ovan kan du skapa ett hög tillgängligt Kubernetes-kluster med lastbalansering via **Kube-VIP**.