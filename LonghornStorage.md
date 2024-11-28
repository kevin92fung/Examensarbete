# Longhorn Storage
## Installations- och konfigurationsguide för Longhorn med Persistent Volumes

#### Översikt över Longhorn Storage
Longhorn är ett open-source, distribuerat blocklagringssystem som är designat för Kubernetes-miljöer. Det gör det möjligt att skapa Persistent Volumes (PVs) och Persistent Volume Claims (PVCs) för dina pods, vilket ger hög tillgänglighet för blocklagring.

Longhorn hanterar blocknivåvolymer som replikeras över flera noder i ditt Kubernetes-kluster för att säkerställa dataredundans och tillgänglighet. När du använder Longhorn med Kubernetes lagras data inom **Persistent Volumes (PVs)** och monteras i containrar via **Persistent Volume Claims (PVCs)**.

Longhorn skapar backuper och snapshots av volymer och lagrar dem på externa mål, som en NAS, för säker lagring. Om ditt kluster eller noder kraschar kan du återställa data från dessa backuper och säkerställa att inga data går förlorade.

#### Longhorn Storage-komponenter
- **Volymer**: Dessa är de faktiska lagringsresurser som Longhorn skapar.
- **Snapshots**: Snapshots är tidpunktskopior av en volym. Longhorn använder dessa för backuper och återställning.
- **Replikor**: Longhorn replikerar data över olika noder för att tillhandahålla hög tillgänglighet.
- **Backup Target**: Longhorn kan skicka backuper till externa mål, som en NAS (via NFS eller SMB).
- **Engine**: Longhorn använder en engine för att hantera volymskapande, replikering och återställning.

#### Dataflöde med Longhorn
1. **Volymskapande**: När du skapar en Persistent Volume Claim (PVC) tilldelar Longhorn en volym som kan användas av din pod.
2. **Datainlagring**: Data skrivs till volymen som monteras i din pod. Longhorn replikerar data över tillgängliga noder i klustret.
3. **Volymbackup**: Longhorn kan säkerhetskopiera volymer till ett externt mål (t.ex. en NAS) för att säkerställa data tillgänglighet vid nodfel.
4. **Återställning**: Vid ett fel kan Longhorn återställa volymer från backuper som lagras på NAS, vilket gör att du kan återuppta verksamheten på nya noder.

---

### Steg för att Installera Longhorn på Kubernetes

**Förutsättningar:**
- Ett Kubernetes-kluster (K3s stöder Longhorn).
- Kubernetes `kubectl` konfigurerat för att hantera ditt kluster.
- **Open-iSCSI** måste vara installerat på varje maskin i klustret för att Longhorn ska kunna använda iSCSI som transportprotokoll.

#### 1. **Installera Open-iSCSI på varje maskin**
För att Longhorn ska fungera korrekt, behöver du installera och aktivera **Open-iSCSI** på varje nod i ditt Kubernetes-kluster. Följ dessa steg:

1. **Installera Open-iSCSI**:
   För Ubuntu/Debian:
   ```bash
   sudo apt-get update
   sudo apt-get install -y open-iscsi
   ```

2. **Aktivera och starta Open-iSCSI-tjänsten**:
   För att säkerställa att tjänsten startar vid uppstart och är igång, kör följande kommandon:
   ```bash
   sudo systemctl enable iscsid
   sudo systemctl start iscsid
   ```

3. **Bekräfta att Open-iSCSI är aktivt**:
   Kontrollera att tjänsten körs korrekt:
   ```bash
   sudo systemctl status iscsid
   ```

   Du bör se att `iscsid` är aktiv och kör.

#### 2. **Installera Longhorn med Kubernetes YAML**

1. Tillämpa Longhorn YAML för att installera Longhorn-komponenterna:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/deploy/longhorn.yaml
   ```
   Detta installerar Longhorn i `longhorn-system`-namnrymden.

2. Bekräfta installationen genom att kolla på pods i `longhorn-system`-namnrymden:
   ```bash
   kubectl get pods -n longhorn-system
   ```

#### 3. **Sätt Longhorn som default StorageClass**

För att slippa specificera `storageClassName: longhorn` i varje Persistent Volume Claim (PVC) kan du sätta Longhorn som default StorageClass:

```bash
kubectl patch storageclass longhorn -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

När detta är gjort kommer alla PVC:er som skapas utan att specificera `storageClassName` automatiskt att använda Longhorn.

#### 4. **Skapa Persistent Volume Claim (PVC) och Pod Exempel**

För att använda Longhorn, skapa en Persistent Volume Claim (PVC) som begär lagring från Longhorn och en pod som monterar denna volym.

1. **Skapa en PVC-fil (`pvc.yaml`)**:

   Om du har satt Longhorn som default StorageClass, behöver du inte specificera `storageClassName` i PVC:n. Här är ett exempel:

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: longhorn-volv-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 2Gi
   ```

   Denna PVC begär 2Gi lagring från Longhorn.

2. **Skapa en Pod-fil (`pod.yaml`)**:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: volume-test
     namespace: default
   spec:
     containers:
     - name: volume-test
       image: nginx:stable-alpine
       imagePullPolicy: IfNotPresent
       volumeMounts:
       - name: volv
         mountPath: /data
       ports:
       - containerPort: 80
     volumes:
     - name: volv
       persistentVolumeClaim:
         claimName: longhorn-volv-pvc
   ```

   Denna pod använder PVC:n som skapats ovan och monterar volymen på `/data` inuti containern.

#### 5. **Skapa PVC och Pod**

Kör följande kommandon för att skapa PVC:n och podden:

```bash
kubectl create -f pvc.yaml
kubectl create -f pod.yaml
```

#### 6. **Verifiera PVC och PV Skapande**

Efter att ha tillämpat YAML-filerna kan du verifiera skapandet av Persistent Volume (PV) och Persistent Volume Claim (PVC):

```bash
kubectl get pv
kubectl get pvc
```

Detta visar statusen för PVC:n och dess associerade PV.

---

### Backup-konfiguration med NAS

1. **Konfigurera Longhorn Backup Target**:  
   Om du vill ställa in ett backupmål på din NAS behöver du konfigurera Longhorn för att använda den som backupplats. Till exempel kan du använda NFS.

2. **Ställ in NFS som Backup Target**:
   - Gå till Longhorn UI, navigera till **Settings** → **Backup**.
   - Ställ in backupmålet för att peka på din NAS via NFS:
     ```plaintext
     nfs://<NAS-IP-ADDRESS>/backup/longhorn
     ```
     Ersätt `<NAS-IP-ADDRESS>` med den faktiska IP-adressen för din NAS.

3. **Aktivera Backup**:
   - Skapa snapshots av dina volymer vid behov.
   - Backuper av snapshots lagras på det konfigurerade backupmålet (NAS).

---

### Sammanfattning av Hur Longhorn Storage Fungerar

- **Persistent Volumes (PVs)** skapas i Longhorn för att tillhandahålla blocklagring för dina Kubernetes-pods.
- **Snapshots** och **backuper** tas regelbundet för att säkerställa dataredundans och återställning vid nodfel.
- **Replikor** hanteras automatiskt av Longhorn för att säkerställa datatillgänglighet över noder.
- Longhorn använder **externa backupmål** som NFS eller SMB (t.ex. en NAS) för att lagra snapshots, vilket säkerställer att data finns kvar även om noder går förlorade.
- För att återställa kan Longhorn återställa volymer från backuper på NAS till nya noder, vilket minimerar stilleståndstid.

Med denna konfiguration kan du på ett säkert sätt hantera persistent lagring, backuper och återställning i din Kubernetes-miljö med Longhorn.

---

För mer detaljerad dokumentation om Longhorn, se den officiella [Longhorn-dokumentationen](https://longhorn.io/docs/).