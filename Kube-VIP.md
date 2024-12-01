# **Kube-VIP: Installation, Konfiguration och Verifiering**

### **Vad är Kube-VIP?**
Kube-VIP är en lösning för att tilldela **Virtuella IP-adresser (VIP)** för **Control Plane** och **tjänster** i Kubernetes-kluster. Kube-VIP gör det möjligt att ha en enhetlig åtkomstpunkt för **Control Plane** via en VIP och hanterar lastbalansering mellan noder och tjänster genom att tilldela VIP:er från en definierad adresspool.

---

## **Förutsättningar:**
- Kubernetes-kluster installerat (t.ex. med K3s eller kubeadm).
- Adresspool definierad för VIP:er.
- Tillgång till en Linux-maskin med `kubectl` installerat.
- Internetåtkomst för att ladda ner den senaste versionen av Kube-VIP.

---

## **Steg 1: Installera Kube-VIP**

1. **Applicera RBAC-manifest** för att ge rättigheter till Kube-VIP:

   För att ge nödvändiga rättigheter till Kube-VIP, kör följande kommando:
   ```bash
   apt install jq -y
   kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
   ```

---

2. **Definiera nödvändiga variabler för VIP-adress, nätverksinterface och senaste Kube-VIP-version**:

   - Byt ut `<IP som ska användas virtuellt>` med din önskade virtuella IP-adress (VIP).
   - Byt ut `<Namn på nätverkskort>` med ditt nätverkskort, exempelvis `eth0`.

   Kör följande kommandon:
   ```bash
   export VIP=<IP som ska användas virtuellt>
   export INTERFACE=<Namn på nätverkskort, t.ex. eth0>
   KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
   ```

---

3. **Ladda ner och skapa manifestet för Kube-VIP**:

   Skapa manifestet för Kube-VIP som DaemonSet:
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

---

4. **Applicera manifestet i Kubernetes**:

   Applicera manifestet för att skapa Kube-VIP DaemonSet:
   ```bash
   kubectl apply -f kube-vip-manifest.yaml
   ```

---

## **Steg 2: Konfigurera Adresspool för Kube-VIP**

För att tilldela VIP:er för tjänster och Control Plane, definiera en adresspool genom att skapa en ConfigMap:

1. **Skapa ConfigMap för Kube-VIP med adresspool**:

   Definiera en adresspool för Kube-VIP genom att ange ett intervall av IP-adresser som Kube-VIP ska använda för att tilldela VIP:er. Byt ut `192.168.1.220-192.168.1.230` med det intervall som passar ditt nätverk.
   ```bash
   kubectl create configmap -n kube-system kubevip --from-literal range-global=192.168.1.220-192.168.1.230
   ```

2. **Verifiera att ConfigMap har skapats korrekt**:

   Kontrollera att ConfigMap har skapats och att inställningarna är korrekta:
   ```bash
   kubectl get configmap -n kube-system kubevip -o yaml
   ```

---

## **Steg 3: Kontrollera och Verifiera Installation**

1. **Verifiera Kube-VIP DaemonSet**:

   Kontrollera att Kube-VIP DaemonSet är korrekt installerad på alla noder:
   ```bash
   kubectl get daemonset -n kube-system kube-vip
   ```

2. **Verifiera VIP för Control Plane**:

   Kontrollera att VIP för Control Plane är korrekt tilldelad och tillgänglig:
   ```bash
   kubectl get nodes -o wide
   ```

3. **Verifiera att VIP:er är tilldelade för tjänster**:

   Kontrollera att VIP:er är tilldelade till tjänster, t.ex. LoadBalancer-tjänster:
   ```bash
   kubectl get svc -A
   ```

4. **Starta om DaemonSet för att säkerställa att alla VIP:er är korrekt tilldelade**:

   Om du gör några förändringar eller vill vara säker på att Kube-VIP tilldelar VIP:er på alla noder, rulla om DaemonSet:
   ```bash
   kubectl rollout restart daemonset kube-vip -n kube-system
   ```

---

## **Steg 4: Omstart av Tjänster för att Säkerställa Funktionalitet**

1. **Starta om Kubelet (om Control Plane VIP inte är tillgänglig)**:

   Om Control Plane VIP inte är korrekt tilldelad, kan du starta om Kubelet:
   ```bash
   sudo systemctl restart kubelet
   ```

2. **Starta om Poddar som Använder VIP:er**:

   Om du har tjänster som använder VIP:er, kan du behöva starta om dessa poddar för att de ska ansluta till rätt VIP:
   ```bash
   kubectl rollout restart deployment <deployment-name> -n <namespace>
   ```

3. **Starta om hela Kubernetes-klustret (i sällsynta fall)**:

   Om ingen av de ovanstående åtgärderna fungerar, kan du prova att starta om hela klustret:
   ```bash
   sudo reboot
   ```

---

## **Sammanfattning av Stegen**:

1. **Installera Kube-VIP** och skapa manifestet för DaemonSet.
2. **Definiera och skapa en adresspool** genom ConfigMap för att tilldela VIP:er.
3. **Verifiera att VIP:erna är tilldelade** för både Control Plane och tjänster.
4. **Starta om Kubelet och DaemonSet** om VIP:er inte tilldelas korrekt.
5. **Verifiera att tjänster och pods använder rätt VIP** och rulla om vid behov.
