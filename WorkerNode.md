# **Installera Worker-noder i K3s Kluster (Raspberry Pi OS och Debian)**

### **Förutsättningar**
- Du har en fungerande **master-nod** i ditt K3s-kluster.
- Du har **token** för att autentisera worker-noderna.
- Raspberry Pi OS (64-bit) eller Debian är installerat på worker-noderna.

### **Steg 1: Förbered Worker-noden**
Oavsett om du använder **Raspberry Pi OS** eller **Debian**, följ dessa steg på varje worker-nod:

1. **Uppdatera systemet**:
   Se till att systemet är uppdaterat:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Installera `wget` (om inte redan installerat)**:
   K3s-installationsskriptet hämtas med `wget`. Om det inte redan är installerat, kör:
   ```bash
   sudo apt install wget -y
   ```

### **Steg 2: Installera K3s på Worker-noden**

Nu installerar vi K3s på varje worker-nod och ansluter den till master-noden.

#### **För Raspberry Pi OS och Debian**

1. **Hämta Token från Master-noden**:
   För att ansluta varje worker-nod till master-noden, behöver du en autentiseringstoken. Kör följande kommando på **master-noden** för att hämta token:
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

   Kopiera den token som visas och notera IP-adressen till master-noden.

2. **Installera K3s på Worker-noden**:
   På varje worker-nod, kör följande kommando för att installera K3s och ansluta till master-noden. Ersätt `<MASTER_IP>` med IP-adressen för master-noden och `<TOKEN>` med den token som du fick från master-noden:
   ```bash
   wget -q -O - https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN> sh -
   ```

   Detta laddar ner och installerar K3s på worker-noden, samt ansluter den till master-noden i klustret.

3. **Verifikationskommando**:
   Efter att K3s har installerats på worker-noden, kan du kontrollera att noderna har anslutit sig till klustret genom att köra följande kommando på **master-noden**:
   ```bash
   sudo kubectl get nodes
   ```

   Detta bör visa alla noder (master och worker-noder) i klustret med deras status, t.ex. `Ready`.

### **Steg 3: Bekräfta att Worker-noden Har Lagt Till sig**

Efter installationen och anslutningen kan du kontrollera att worker-noden har lagts till och att klustret fungerar korrekt.

1. **Kontrollera noder på master-noden**:
   Kör följande kommando på master-noden för att säkerställa att alla noder (både master och worker-noder) är i "Ready"-status:
   ```bash
   sudo kubectl get nodes
   ```

   Du bör se en lista med alla noder i klustret. Exempel på utdata:
   ```bash
   NAME           STATUS   ROLES    AGE   VERSION
   master-node    Ready    master   5d    v1.21.0+k3s1
   worker-node-1  Ready    <none>   5d    v1.21.0+k3s1
   worker-node-2  Ready    <none>   5d    v1.21.0+k3s1
   ```

   Om alla noder har `Ready`-status, betyder det att de har anslutit och klustret är korrekt konfigurerat.

### **Steg 4: Hantera och Distribuera Pods**
När alla worker-noder är anslutna kan du börja distribuera Pods på klustret. Här är ett exempel på hur du skapar en Pod på ditt K3s-kluster.

Exempel: Skapa en NGINX-Pod med tre repliker:
```bash
kubectl run my-nginx --image=nginx --replicas=3
```

Detta kommando skapar en Pod som kör en nginx-container och distribuerar den på dina worker-noder i klustret.

---

## **Vanliga Problem och Lösningar**

- **Token inte korrekt**: Om du får ett felmeddelande om ogiltig token, se till att du hämtar den korrekta token från master-noden och att den används exakt som den visas.
  
- **Kommunikationsproblem mellan noder**: Se till att master-noden och worker-noderna är på samma nätverk och att inga brandväggsregler blockerar port 6443 (som används av K3s för kommunikation).

- **`kubectl get nodes` visar noder som inte är i "Ready"**: Om en worker-nod inte visas som "Ready", kontrollera loggarna för den noden. Du kan använda:
  ```bash
  journalctl -u k3s-agent -f
  ```

  Detta kommer att visa loggar för k3s-agenten och kan ge mer information om varför en nod inte kan ansluta.


## Montera NAS
Installera nfs-common
```bash
sudo apt install nfs-common -y
```
lägg till följande i /etc/fstab
```bash
<IPTillNAS>:/export/<share> </mnt/nas> nfs defaults 0 0
```
montera NAS
```bash
sudo mount -a
```