## Guide för att installera Longhorn och Portainer i K3s

### Förberedelser
Se till att K3s är installerat på din maskin och att Longhorn har installerats som standard storage class på din K3s-kluster. Om du inte har installerat Longhorn än, följ dessa steg:

### Steg 1: Installera Longhorn
För att installera Longhorn i din K3s-kluster, kör följande kommando:

```bash
kubectl create namespace longhorn-system
kubectl apply -n longhorn-system -f https://github.com/longhorn/longhorn/releases/download/v1.3.2/longhorn-install.yaml
```

Detta kommer att installera Longhorn som ett StatefulSet och skapa alla nödvändiga resurser för att hantera lagring i din Kubernetes-kluster.

### Steg 2: Installera Portainer
När Longhorn är installerat och konfigurerat i din K3s-kluster, kan du gå vidare med installationen av Portainer för att hantera din Kubernetes-kluster via ett webbaserat gränssnitt.

Kör följande kommando för att installera Portainer:

```bash
kubectl apply -n portainer -f https://downloads.portainer.io/ce2-21/portainer.yaml
```

Detta kommer att installera Portainer i `portainer`-namnrymden och öppna upp Portainer via NodePort. Du kommer att kunna nå Portainer via de följande portarna:
- **HTTP**: `30777`
- **HTTPS**: `30779`

### Steg 3: Åtkomst till Portainer UI
När Portainer har installerats, öppna din webbläsare och gå till följande adresser:

- HTTP: `http://<virtuellt-ip>:30777`
- HTTPS: `https://<virtuellt-ip>:30779`

Byt ut `<virtuellt-ip>` mot IP-adressen för din master-node eller den virtuella maskinen där K3s är installerat.

### Steg 4: Skapa ett lösenord
Vid första åtkomst till Portainer UI kommer du att bli ombedd att skapa ett administratörslösenord. Ange ett säkert lösenord och fortsätt.

### Steg 5: Lägg till Kubernetes som miljö
1. När du är inloggad i Portainer, gå till huvudmenyn och klicka på **"Add Environment"**.
2. Välj **Kubernetes** som typ av miljö.
3. Välj **Agent** som anslutningsmetod.
4. Under **Kubernetes via NodePort**, kopiera den kod som visas.

### Steg 6: Koppla Portainer till din Kubernetes-kluster
För att koppla Portainer till din Kubernetes-kluster måste du köra den kopierade koden på master-noden i din kluster. Kör följande kommando på master-noden:

```bash
kubectl apply -f <kopierad-kod>.yaml
```

Detta kommer att skapa en agent i din kluster och koppla den till Portainer.

### Steg 7: Live Connect för att ansluta till Kubernetes
1. Gå till **Home** på Portainer UI.
2. Klicka på **"Live Connect"** för att ansluta Portainer till Kubernetes och börja hantera din kluster direkt via Portainer.

Nu har du framgångsrikt installerat Portainer och kopplat den till din K3s-kluster med Longhorn som standard storage class.