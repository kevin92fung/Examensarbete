# StorageClass för NFS-lagring

I denna guide konfigurerar vi ett Kubernetes-kluster där NAS-lagringen används som en **Persistent Volume (PV)**, inklusive steg för att konfigurera StorageClass, ändra standard StorageClass och verifiera att allt fungerar.

---

## **1. Förberedelser på alla noder (Master och Worker)**

### 1.1 **Se till att Kubernetes-noderna har NFS-stöd**

Installera **nfs-common** på alla noder i klustret (både master och worker):

```bash
sudo apt update && sudo apt install -y nfs-common
```

---

### 1.2 **Skapa monteringsmappen på alla noder** (både master och worker)

Om mappen `/mnt/NAS` inte finns, skapa den med följande kommando:

```bash
mkdir -p /mnt/NAS
```

---

### 1.3 **Lägg till NFS-mount i `/etc/fstab` på alla noder**

Lägg till en rad i `/etc/fstab` på alla noder (master och worker) för att säkerställa att NFS-resursen monteras automatiskt vid uppstart. Ersätt `<ip-till-nas>` med din NFS-server-IP och `<nas-mappen>` med den delade katalogen:

```bash
echo "<ip-till-nas>:/export/<nas-mappen> /mnt/NAS nfs defaults 0 0" | sudo tee -a /etc/fstab
```

---

### 1.4 **Montera NFS-resursen på alla noder**

Montera NFS-resursen omedelbart:

```bash
sudo mount -a
```

Kontrollera att NFS är monterad korrekt:

```bash
mount | grep /mnt/NAS
```

---

## **2. Konfigurera och hantera StorageClass**

### 2.1 **Skapa en StorageClass för NFS**

Skapa en fil med namnet `storageclass.yaml` och klistra in följande innehåll:

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

Använd följande kommando för att skapa StorageClass:

```bash
kubectl apply -f storageclass.yaml
```

---

### 2.2 **Ändra standard StorageClass**

#### Sätt `nfs-storage` som standard:
```bash
kubectl patch storageclass nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Ta bort den gamla standard StorageClass:
Om du exempelvis har `local-path` som standard och vill ta bort den som default:

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

#### Verifiera ändringarna:
Kör följande kommando för att se att `(default)` nu är inställt på `nfs-storage`:

```bash
kubectl get storageclass
```

Resultatet bör visa att `nfs-storage` är standard och att den gamla StorageClass inte längre har `(default)`.

---

## **3. Skapa en PersistentVolumeClaim (PVC)**

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
  storageClassName: nfs-storage  # Använd vår nya StorageClass
```

### 3.2 **Tillämpa PVC-konfigurationen**:

```bash
kubectl apply -f pvc-nfs.yaml
```

---

## **4. Verifiera och kontrollera**

### 4.1 **Kontrollera om PVC har skapats**
```bash
kubectl get pvc
```

### 4.2 **Verifiera att rätt StorageClass används**
```bash
kubectl describe pvc nfs-pvc
```
Under `StorageClass` ska du se `nfs-storage`.

---

Nu är din NFS-lagring konfigurerad och redo att användas i Kubernetes som standardlagring för alla PersistentVolumeClaims! 🎉