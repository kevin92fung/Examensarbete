## Installationsskript för att sätta upp ett K3S-kluster

### Förberedelser
1. Minst 5 virtuella maskiner med Ubuntu/Debian eller 5x Raspberry Pi.
2. Statiskt IP för varje enhet.
3. Root-åtkomst till varje enhet.
---

### Initiera K3S
**Detta skript installerar den första master-noden, sätter upp Kube-VIP som Daemonset, tilldelar kontrollplanet ett virtuellt IP och tilldelar en IP-pool för lastbalanseraren.**
Kube-vip är en lastbalancerings tjänst
Daemonset innebär att den kör på alla noder som uppfylelr kraven, i detta fall master noder

```bash
#Byt ut variabler för username, VIP och INTERFACE
export username='kevin'
export VIP='192.168.3.220'
export INTERFACE='eth0'
export VIP_RANGE="192.168.3.230-192.168.3.250"

apt update
apt install curl wget jq nfs-common sudo -y
usermod -aG sudo $username
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers

curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
--cluster-init \
--tls-san=$VIP \
--disable=traefik \
--disable=servicelb \
--node-taint CriticalAddonsOnly=true:NoExecute

# Wait for all nodes to be ready
until kubectl get nodes | grep 'Ready'; do
    echo "Waiting for nodes to be ready..."
    sleep 5
done

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
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
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml
kubectl create configmap -n kube-system kubevip --from-literal range-global=$VIP_RANGE
```
---

### Lägg till Master noder i klustert
**Detta skript lägger till master-noder i klustret**
```bash
#Byt ut variabler för username och VIP
export username='kevin'
export VIP='192.168.3.220'

apt update
apt install curl wget jq nfs-common sudo -y
usermod -aG sudo $username
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers

curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
--tls-san=$VIP \
--server https://$VIP:6443 \
--disable=traefik \
--disable=servicelb \
--node-taint CriticalAddonsOnly=true:NoExecute
```
---


### Lägg till Worker noder i klustret
**Detta skript lägger till Worker-noder i klustret**
```bash
#Byt ut variabler för username, VIP
export username='kevin'
export VIP='192.168.3.220'
apt update
apt install curl wget jq nfs-common open-iscsi sudo -y
usermod -aG sudo $username
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
systemctl enable iscsid
systemctl start iscsid
curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - agent \
    --server https://$VIP:6443
```
