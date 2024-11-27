# StorageClass för NFS-lagring

### **Guide för att använda hela NAS-lagringen som en Persistent Volume i Kubernetes**

I denna guide konfigurerar vi ett Kubernetes-kluster där NAS-lagringen används som ett **Persistent Volume (PV)**, vilket gör hela lagringsutrymmet tillgängligt. Detta inkluderar steg för att konfigurera både master- och worker-noder.

---

## **1. Förberedelser på alla noder (Master och Worker)**

### 1.1 **Se till att Kubernetes-noderna har NFS-stöd**

Installera **nfs-common** på alla noder i klustret (både master och worker):
```bash
sudo apt update && sudo apt install -y nfs-common
```

---

### 1.2 **Skapa monteringsmappen på alla noder** (både master och workers):
Om mappen `/mnt/NAS` inte finns, skapa den med följande kommando:
```bash
mkdir -p /mnt/NAS
```

---

### 1.3 **Lägg till NFS-mount i `/etc/fstab` på alla noder**:
För att säkerställa att NFS-resursen monteras automatiskt vid uppstart på varje nod, använd `echo` för att lägga till en rad i `/etc/fstab` på alla noder (master och worker). Ersätt `<ip-till-nas>` med IP-adressen på din NFS-server och `<nas-mappen>` med den delade katalogen på din NAS.

Exempel:
```bash
echo "<ip-till-nas>:/export/<nas-mappen> /mnt/NAS nfs defaults 0 0" | sudo tee -a /etc/fstab
```
Detta lägger till en rad i `/etc/fstab` som säkerställer att NFS-resursen monteras vid varje uppstart på alla noder.

---

### 1.4 **Montera NFS-resursen på alla noder**:
Efter att ha lagt till raden i `/etc/fstab`, kan du montera NFS-resursen omedelbart på alla noder med:
```bash
sudo mount -a
```
Kontrollera att NFS är monterad korrekt på alla noder:
```bash
mount | grep /mnt/NAS
```

---

## **2. Konfigurera StorageClass**

### 2.1 **Skapa en fil med namnet `storageclass.yaml`** och klistra in följande innehåll:
   ```yaml
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: nfs-storage
   provisioner: kubernetes.io/nfs
   parameters:
     server: <NFS-server-ip>  # Ersätt med IP-adressen eller DNS-namnet på din NFS-server
     path: /path/to/nfs/share  # Ersätt med sökvägen till den delade NFS-katalogen
   reclaimPolicy: Retain  # Volymen behålls även när den inte längre används
   volumeBindingMode: Immediate  # Bindningen sker omedelbart
   ```

### 2.2 **Använd kommandot `kubectl apply` för att tillämpa konfigurationen**:
   ```bash
   kubectl apply -f storageclass.yaml
   ```
   Detta skapar en **StorageClass** som kan användas för att skapa **Persistent Volumes**.

---

## **3. Skapa en PersistentVolumeClaim (PVC)**

Nu skapar vi en **PersistentVolumeClaim (PVC)** som använder den tidigare skapade **StorageClass** för att begära lagring från NFS-servern.

### 3.1 **Skapa en YAML-fil för PVC** (t.ex. `pvc-nfs.yaml`):

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: nfs-pvc
   spec:
     accessModes:
       - ReadWriteMany  # För att tillåta åtkomst från flera noder
     resources:
       requests:
         storage: 10Gi  # Anpassa efter dina behov
     storageClassName: nfs-storage  # Här hänvisar du till StorageClass vi skapade tidigare
   ```

### 3.2 **Tillämpa PVC-konfigurationen**:
   ```bash
   kubectl apply -f pvc-nfs.yaml
   ```

---

## **4. Verifiera och kontrollera**

### 4.1 **Kontrollera om PVC har skapats** och om volymen är tilldelad korrekt:
  ```bash
  kubectl get pvc
  ```

### 4.2 **Kontrollera podden**:
  ```bash
  kubectl get pod nfs-example
  ```

### 4.3 **Verifiera lagringen** genom att ansluta till Poden och kolla om volymen är monterad korrekt:
  ```bash
  kubectl exec -it nfs-example -- /bin/sh
  ls /usr/share/nginx/html
  ```