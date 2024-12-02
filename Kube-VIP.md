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

Självklart! Här kommer en sektion som förklarar hur du öppnar upp en service mot en av adresserna i VIP-poolen, inklusive exempel på hur du kan tilldela en specifik IP från poolen.

---

## **Steg 5: Exponera en Service med VIP från Adresspoolen**

För att öppna upp en service och tilldela den en VIP från den adresspool som definierats, kan du använda `LoadBalancer`-typen för din Kubernetes-service. Här är stegen för att exponera en service via en specifik VIP-adress från poolen.

### **Exempel på en Service som Användar VIP från Poolen**

Antag att vi har en service som vi vill exponera, t.ex. **Longhorn** (en lagringstjänst). Vi vill att denna service ska använda en IP från adresspoolen, exempelvis `<ip-från-pool>` (ersätt detta med en faktisk IP från din adresspool, som t.ex. `192.168.1.225`).

1. **Skapa en Service med LoadBalancer-typ**:

   Här är ett exempel på en YAML-definition för en Kubernetes-service som använder VIP från poolen. I detta fall tilldelar vi VIP till en `LoadBalancer`-service.

   Skapa en fil, t.ex. `longhorn-service.yaml`, och använd följande innehåll:

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: longhorn
     namespace: longhorn-system
   spec:
     selector:
       app: longhorn
     ports:
       - protocol: TCP
         port: 80
         targetPort: 80
     type: LoadBalancer
     loadBalancerIP: <ip-från-pool>
   ```

   - **loadBalancerIP:** Här sätter vi den specifika IP-adressen från adresspoolen, som du vill att denna tjänst ska exponeras på. Exempel: `loadBalancerIP: 192.168.1.225`.

2. **Applicera YAML-filen för att skapa tjänsten**:

   Kör följande kommando för att skapa och tillämpa servicen i ditt kluster:

   ```bash
   kubectl apply -f longhorn-service.yaml
   ```

3. **Verifiera att servicen är skapad och tilldelad rätt IP**:

   Efter att du har tillämpat manifestet, kan du kontrollera att servicen har tilldelats rätt VIP från adresspoolen genom att köra:

   ```bash
   kubectl get svc longhorn -n longhorn-system
   ```

   Detta kommando ska ge ett resultat liknande följande:

   ```
   NAME      TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
   longhorn  LoadBalancer   10.96.0.1      192.168.1.225   80:31322/TCP   5m
   ```

   Här ser du att **EXTERNAL-IP** är satt till den IP-adress från adresspoolen som du har tilldelat, i detta fall `192.168.1.225`.

4. **Testa åtkomst till tjänsten via den tilldelade VIP-adressen**:

   Efter att du har skapat servicen och verifierat att den har fått en extern IP, kan du testa att nå tjänsten via den VIP-adress som du har tilldelat.

   Öppna en webbläsare eller använd ett verktyg som `curl` för att testa åtkomsten till tjänsten. I detta exempel, om du exponerar Longhorn på port 80, kan du göra följande:

   ```bash
   curl http://192.168.1.225
   ```

   Detta ska ge dig åtkomst till tjänsten via den externa VIP-adressen som du har tilldelat.

---

## **Sammanfattning av Stegen för att Installera Kube-VIP och Exponera en Service med VIP från Poolen**

### **Installation av Kube-VIP**

1. **Installera Kube-VIP** och skapa manifestet för DaemonSet:
   - Installera RBAC och skapa ett manifest för att konfigurera Kube-VIP på ditt Kubernetes-kluster.
   - Definiera VIP, nätverksinterface och andra parametrar för Kube-VIP.

2. **Definiera och skapa en adresspool** genom ConfigMap:
   - Skapa en ConfigMap för att definiera ett IP-intervall (adresspool) för VIP:er.
   - Exempel: `kubectl create configmap -n kube-system kubevip --from-literal range-global=192.168.1.220-192.168.1.230`.

3. **Applicera manifestet för Kube-VIP** och starta DaemonSet:
   - Kör `kubectl apply -f kube-vip-manifest.yaml` för att starta Kube-VIP och börja hantera VIP:er för både Control Plane och tjänster.

4. **Verifiera att VIP:erna är tilldelade**:
   - Kontrollera att VIP:erna har tilldelats korrekt för både Control Plane och tjänster genom att använda kommandon som `kubectl get svc` för att säkerställa att rätt adresser används.

5. **Starta om Kubelet och DaemonSet** om VIP:er inte tilldelas korrekt:
   - Om VIP:erna inte tilldelas korrekt, rulla om DaemonSet eller starta om Kubelet för att säkerställa att inställningarna tillämpas.

---

### **Exponera en Service med VIP från Poolen**

1. **Skapa en `LoadBalancer`-service** i Kubernetes med en specifik `loadBalancerIP` från adresspoolen:
   - Skapa en YAML-fil för tjänsten och tilldela den en specifik IP-adress från adresspoolen. Exempel: `loadBalancerIP: 192.168.1.225`.

2. **Applicera YAML-filen för att skapa och exponera servicen**:
   - Kör `kubectl apply -f longhorn-service.yaml` för att skapa och exponera servicen.

3. **Verifiera att servicen har tilldelats rätt VIP**:
   - Kontrollera att servicen har tilldelats rätt VIP genom att köra: `kubectl get svc longhorn -n longhorn-system`.

4. **Testa åtkomst till servicen via den tilldelade VIP-adressen**:
   - Testa att du kan komma åt tjänsten via den tilldelade VIP-adressen genom att använda `curl` eller en webbläsare.

---

Denna guide ger dig en komplett process för att installera och konfigurera Kube-VIP för att hantera VIP:er för både **Control Plane** och **tjänster**, samt hur du exponerar en service och tilldelar den en specifik IP från din adresspool. Detta gör att du kan ha en mer kontrollerad nätverksåtkomst till dina tjänster inom Kubernetes-klustret.

