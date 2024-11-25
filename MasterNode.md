# **Installera K3s på Raspberry Pi 5 Kluster (Raspberry Pi OS och Debian)**

Denna guide förklarar hur du sätter upp ett Kubernetes-kluster på Raspberry Pi 5-enheter (8GB) med hjälp av **K3s**, den lättviktiga versionen av Kubernetes som passar bra för enheter som Raspberry Pi. Vi kommer att täcka både **Raspberry Pi OS** och **Debian**.

### **Förutsättningar**

- En Raspberry Pi 5-enhet som master-nod.
- Två eller fler Raspberry Pi 5-enheter som worker-noder.
- Raspberry Pi OS (64-bit) eller Debian installerat på alla enheter.
- Grundläggande nätverksåtkomst mellan enheterna.

### **Steg 1: Förbered Raspberry Pi-enheterna**

#### **Raspberry Pi OS (64-bit) eller Debian**
För både Raspberry Pi OS och Debian behöver du ett 64-bitars operativsystem. På Raspberry Pi 5 rekommenderas Raspberry Pi OS (64-bit), men Debian fungerar också bra. Här är stegen för att förbereda alla enheter.

1. **Uppdatera systemet**:
   På varje enhet, kör följande kommandon:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Installera nödvändiga verktyg**:
   För att hämta K3s-installationsskriptet, installera `wget` (om det inte redan är installerat):
   ```bash
   sudo apt install wget -y
   ```

### **Steg 2: Installera K3s på Master-noden**

Välj en av dina Raspberry Pi-enheter att vara **master-nod**.

1. **Installera K3s med flaggan `--no-taint-master`**:
   För att se till att master-noden kan köra användarpods, använd flaggan `--no-taint-master` när du installerar K3s. Detta gör att master-noden inte får den taint som normalt hindrar användarpods från att schemaläggas där. Kör följande kommando på master-noden:
   ```bash
   wget -q -O - https://get.k3s.io | sh -s - --no-taint-master
   ```

2. **Kontrollera installationen**:
   När installationen är klar, kontrollera att K3s är igång och att master-noden har registrerats korrekt:
   ```bash
   sudo kubectl get nodes
   ```

   Du bör nu se din master-nod listad som `Ready`.

### **Steg 3: Installera K3s på Worker-noder**

På varje Raspberry Pi-enhet som ska fungera som **worker-nod**, kör följande steg:

1. **Hämta Token från Master-noden**:
   För att lägga till worker-noder, behöver du en autentiseringstoken från master-noden. På master-noden, kör:
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

   Kopiera token och notera IP-adressen för master-noden.

2. **Installera K3s på Worker-noder**:
   På varje worker-nod, kör följande kommando och ersätt `<MASTER_IP>` med IP-adressen till master-noden och `<TOKEN>` med token som du fick från master-noden:
   ```bash
   wget -q -O - https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN> sh - 
   ```

3. **Verifikationskommando**:
   Efter installationen på worker-noderna, kör följande kommando på master-noden för att säkerställa att alla noder har anslutit sig korrekt:
   ```bash
   sudo kubectl get nodes
   ```

   Du bör nu se både master-noden och worker-noderna listade som `Ready`.

### **Steg 4: Bekräfta Klustret**

Nu när K3s är installerat på både master-noden och worker-noderna, kan du kontrollera att alla noder är i rätt status genom att köra:
```bash
sudo kubectl get nodes
```

Du bör se alla noder (master och workers) i `Ready`-status.

---

## **Vanliga Felsökningar**

- **Om noder inte visas**: Kontrollera att alla enheter är på samma nätverk och att ingen brandvägg blockerar port 6443.
- **Om installationen misslyckas**: Se till att din Raspberry Pi har tillräckligt med lagringsutrymme och att den senaste versionen av K3s används.


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