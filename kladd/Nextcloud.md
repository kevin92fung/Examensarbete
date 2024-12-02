# Installation av Nextcloud

Den här guiden beskriver hur du installerar och konfigurerar Nextcloud i Kubernetes, med MariaDB som databas. Vi börjar med att installera MariaDB och sedan Nextcloud.

## Steg 1: Installera och konfigurera MariaDB

Först behöver vi installera MariaDB i Kubernetes och konfigurera den så att den fungerar med Nextcloud.

### 1.1 Base64-koda lösenordet

För att skapa ett säkert root-lösenord för MariaDB, använd följande kommando för att base64-koda lösenordet:

```bash
echo -n password12345 | base64
```

Det här kommandot returnerar den base64-kodade strängen för ditt lösenord. Exempelvis:

```
cGFzc3dvcmQxMjM0NQ==
```

Byt ut det base64-kodade lösenordet i YAML-filen nedan.

---

### 1.2 Skapa YAML-konfiguration för MariaDB

Använd följande YAML för att skapa ett namespace, secret, persistent volume claim (PVC), deployment och service för MariaDB.

#### `nextcloud.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nextcloud
---
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-secrets
  namespace: nextcloud
type: Opaque
data:
  root-password: cGFzc3dvcmQxMjM0NQ==  # Ersätt med ditt base64-kodade lösenord
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
  namespace: nextcloud
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: nextcloud
  labels:
    app: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
        - name: mariadb
          image: mariadb:latest
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mariadb-secrets
                  key: root-password
            - name: MYSQL_DATABASE
              value: nextcloud
          ports:
            - containerPort: 3306
          volumeMounts:
            - name: mariadb-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mariadb-storage
          persistentVolumeClaim:
            claimName: mariadb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb
  namespace: nextcloud
spec:
  selector:
    app: mariadb
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
  clusterIP: None  # För att använda en headless service för podden
```

---

### 1.3 Applicera YAML-filen

Kör följande kommando för att applicera konfigurationen i Kubernetes:

```bash
kubectl apply -f nextcloud.yaml
```

Detta skapar:

- **Namespace** `nextcloud`
- **Secret** för MariaDB root-lösenordet
- **PVC** för lagring
- **Deployment** för MariaDB
- **Service** för MariaDB (headless)

---

### 1.4 Verifiera att MariaDB fungerar

1. **Kontrollera pod-status**:

   Kör följande kommando för att verifiera att MariaDB-podden är igång:

   ```bash
   kubectl get pods -n nextcloud
   ```

   Du bör se en pod som är i status `Running`.

2. **Koppla upp dig i podden**:

   För att komma åt MariaDB-podden och köra MySQL-kommandon, använd:

   ```bash
   kubectl exec -it -n nextcloud <mariadb-pod-id> -- bash
   ```

   Ersätt `<mariadb-pod-id>` med ID för din MariaDB-pod, som du får från `kubectl get pods` kommandot.

3. **Logga in i MariaDB**:

   När du är i podden, logga in på MariaDB med följande kommando:

   ```bash
   mariadb -u root -p
   ```

   När du blir ombedd om lösenord, använd det root-lösenordet som du base64-kodat tidigare.

4. **Verifiera databas och tabeller**:

   För att kontrollera att MariaDB-databasen och tabellerna finns, kör följande SQL-kommandon:

   - Visa databaser:

     ```sql
     SHOW DATABASES;
     ```

   - Byt till `nextcloud`-databasen:

     ```sql
     USE nextcloud;
     ```

   - Visa tabeller:

     ```sql
     SHOW TABLES;
     ```

   Om databasen och tabellerna är korrekt skapade, bör du nu se en lista med tabeller som Nextcloud använder.

---

## Steg 2: Installation av webbserver
För att Nextcloud ska fungera beövs en webbserver, den webserver som nextcloud rekommenderar är Apache.

För att lägga till Apache för nextcloud lägger vi in följande i `nextcloud.yaml`
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: apache-pvc
  namespace: nextcloud
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
  namespace: nextcloud
  labels:
    app: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
        - name: apache
          image: httpd:latest
          ports:
            - containerPort: 80
          volumeMounts:
            - name: apache-storage
              mountPath: /usr/local/apache2/htdocs
      volumes:
        - name: apache-storage
          persistentVolumeClaim:
            claimName: apache-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: apache
  namespace: nextcloud
spec:
  selector:
    app: apache
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  clusterIP: None  # Headless service to connect to the pod directly
  ```
### Förklaring:
- PersistentVolumeClaim: Skapar ett PVC för Apache så att det kan ha lagringsutrymme för att serva Nextclouds filer. PVC:n begär 5 GB lagring, vilket kan justeras beroende på behov.
- Deployment: Skapar en Deployment för Apache-webbservern. Den kör den senaste versionen av httpd (Apache) och exponerar port 80. Vi monterar PVC:n på /usr/local/apache2/htdocs, vilket är standardplatsen för Apache att serva filer.
- Service: Skapar en headless Service för Apache, vilket gör att andra tjänster eller användare kan komma åt Apache-servern via den här tjänsten. Vi använder port 80.

### Applicera YAML-filen
Kör följande kommando för att applicera konfigurationen i Kubernetes:
```bash
kubectl apply -f nextcloud.yaml
```
