### **Guide för att använda hela NAS-lagringen som en Persistent Volume i Kubernetes**

I denna guide konfigurerar vi ett Kubernetes-kluster där NAS-lagringen används som ett **Persistent Volume (PV)**, vilket gör hela lagringsutrymmet tillgängligt. Detta inkluderar steg för att konfigurera både master- och worker-noder.

---

## **1. Förberedelser**

1. **Se till att NAS är monterad på alla noder** (både master och workers):
   - NAS är monterad på en specifik mapp, exempelvis `/mnt/NAS`.
   - Kontrollera att NAS är inlagd i `/etc/fstab` på varje nod och är korrekt monterad:
     ```bash
     cat /etc/fstab
     mount | grep /mnt/NAS
     ```

2. **Se till att Kubernetes-noderna har NFS-stöd**:
   - Installera **nfs-common** på alla noder:
     ```bash
     sudo apt update && sudo apt install -y nfs-common
     ```

---

## **2. Konfiguration av Persistent Volume**

### **På master-noden:**

1. **Skapa en Persistent Volume (PV):**
   - Detta PV kommer att använda hela NAS-lagringen.

   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: nas-pv
   spec:
     capacity:
       storage: 100Ti # Ange en stor siffra för att indikera "all lagring"
     accessModes:
       - ReadWriteMany
     nfs:
       path: /mnt/NAS # Path på NAS som används
       server: 192.168.3.210 # NAS-serverns IP-adress
     persistentVolumeReclaimPolicy: Retain
   ```

   Spara detta i en fil, t.ex. `nas-pv.yaml`, och skapa resursen:
   ```bash
   kubectl apply -f nas-pv.yaml
   ```

2. **Skapa en Persistent Volume Claim (PVC):**
   - PVC används för att begära lagring från PV. Här begär vi all tillgänglig lagring.

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: nas-pvc
   spec:
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 100Ti # Begär hela utrymmet
   ```

   Spara detta i en fil, t.ex. `nas-pvc.yaml`, och skapa resursen:
   ```bash
   kubectl apply -f nas-pvc.yaml
   ```

---

## **3. Konfiguration av pods**

Nu när PVC är redo, kan du använda den i pods.

### **Exempel på pod som använder PVC:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-nas
spec:
  containers:
  - name: app-container
    image: nginx
    volumeMounts:
    - name: nas-storage
      mountPath: /usr/share/nginx/html # Mount path in container
  volumes:
  - name: nas-storage
    persistentVolumeClaim:
      claimName: nas-pvc
```

Spara detta i en fil, t.ex. `pod-with-nas.yaml`, och skapa resursen:
```bash
kubectl apply -f pod-with-nas.yaml
```

---

## **4. Inställningar för master- och worker-noder**

1. **Alla noder (master och workers):**
   - Säkerställ att `/mnt/NAS` är monterat och tillgängligt på samma plats på alla noder:
     ```bash
     ls /mnt/NAS
     ```
   - Installera nfs-common om det inte redan är installerat:
     ```bash
     sudo apt update && sudo apt install -y nfs-common
     ```

2. **Verifiera att NAS är tillgänglig från alla noder:**
   - Testa att manuellt lista filer på NAS från varje nod:
     ```bash
     ls /mnt/NAS
     ```

---

## **5. Validering**

1. Kontrollera att PV och PVC är bundna:
   ```bash
   kubectl get pv
   kubectl get pvc
   ```

   Utdata ska visa att PV är **Bound** till PVC.

2. Kontrollera att poden fungerar:
   ```bash
   kubectl get pods
   kubectl describe pod app-with-nas
   ```

3. Kontrollera att filerna på NAS syns i din pod:
   ```bash
   kubectl exec -it app-with-nas -- ls /usr/share/nginx/html
   ```

---

## **6. Rengöring (valfritt)**

Om du behöver ta bort resurser:
```bash
kubectl delete -f nas-pv.yaml
kubectl delete -f nas-pvc.yaml
kubectl delete -f pod-with-nas.yaml
```

---

### **Sammanfattning**
Med denna guide kan du använda hela NAS som ett Persistent Volume och göra det tillgängligt för dina Kubernetes-pods. PVC gör hanteringen av lagringen flexibel och dynamisk, vilket är perfekt för kluster med flera noder.