# Full Guide: Installera och Använda Helm på Kubernetes

Helm är en kraftfull pakethanterare för Kubernetes som förenklar hanteringen av applikationer och resurser i ditt kluster. I denna guide kommer vi att gå igenom hur du installerar Helm, konfigurerar repositories, söker efter och installerar charts, samt hur du hanterar applikationer i Kubernetes-klustret med Helm.

## Vad är Helm?

Helm är ett verktyg som gör det enkelt att hantera applikationer i Kubernetes genom att använda **charts**. Ett chart är en samling av YAML-filer som beskriver alla resurser och inställningar som krävs för att köra en applikation på Kubernetes, som pods, tjänster, volymer, m.m.

### Fördelar med Helm:
- **Enkel installation och uppdatering:** Installera och uppdatera applikationer genom enkla kommandon.
- **Versionering:** Helm charts är versionerade, vilket gör det enkelt att hålla koll på och hantera applikationens versioner.
- **Delning av applikationer:** Helm gör det möjligt att dela och återanvända applikationer genom offentliga och privata repositories.
- **Konfigurationshantering:** Anpassa enkelt applikationer för olika miljöer genom att justera konfigurationsvärden.

## Installera Helm

För att komma igång med Helm, följ dessa steg för att installera det på din maskin. Den här guiden använder ett skript för att installera Helm på en Linux-baserad maskin (t.ex. Ubuntu).

### Ladda ner och installera Helm

**Ladda ner installatörsskriptet:**
   Först laddar vi ner skriptet som installerar den senaste versionen av Helm.
   ```bash
   # Ladda ner Helm-paketet
   curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

   # Ge körbehörighet till skriptet
   chmod 700 get_helm.sh

   # Kör skriptet för att installera Helm
   ./get_helm.sh

   # Radera Helm-paketet
   rm get_helm.sh

   # Verifiera installationen
   helm version

   # Lägg till miljövariabel till K3S för Helm
   echo "KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment
   # Läs in miljövariabeln
   source /etc/environment
   ```

---

## Konfigurera Helm Repository

Helm använder repositories för att lagra och hämta charts. För att installera charts från ett repository, måste du lägga till och uppdatera repositories.

### Steg 2: Lägg till ett Helm-repository

Helm levereras med ett standardrepository, men du kan också lägga till andra offentliga eller privata repositories. För att lägga till det officiella Helm-stable-repositoryt, kör följande kommando:
```bash
helm repo add stable https://charts.helm.sh/stable
```

Detta kommando lägger till det stabila Helm-repositoryt som innehåller ett stort antal populära applikationer.

### Steg 3: Uppdatera Helm-repository

Efter att du lagt till ett repository, behöver du uppdatera Helm så att den får den senaste informationen om tillgängliga charts:
```bash
helm repo update
```

Detta laddar ner den senaste listan med charts från alla repositorys som du har lagt till.

---

## Söka och Installera Helm Charts

Nu när Helm och repositoryn är konfigurerade kan du börja söka efter och installera charts.

### Steg 4: Sök efter Helm Charts

För att söka efter ett specifikt chart i Helm-repositoryt, använd följande kommando:
```bash
helm search repo <chart-namn>
```
Byt ut `<chart-namn>` med namnet på applikationen eller tjänsten du söker efter. Till exempel:
```bash
helm search repo nginx
```

Detta kommando kommer att söka efter ett chart som heter "nginx" i ditt repository och visa resultatet.

### Steg 5: Installera ett Helm Chart

För att installera ett chart från repositoryt, använd följande kommando:
```bash
helm install <release-namn> <chart-namn>
```
Byt ut `<release-namn>` med ett valfritt namn för din installation och `<chart-namn>` med det faktiska chart-namnet. Till exempel:
```bash
helm install my-nginx stable/nginx
```

Detta installerar Nginx från Helm-stable repositoryt och ger installationen namnet "my-nginx".

---

## Hantera Helm Charts

Helm gör det enkelt att hantera och uppdatera applikationer som du har installerat. Här är några kommandon för att hantera installationsuppdateringar och borttagningar.

### Steg 6: Uppdatera en installation

För att uppdatera en installerad applikation, använd följande kommando:
```bash
helm upgrade <release-namn> <chart-namn>
```
Till exempel, om du vill uppgradera "my-nginx" till den senaste versionen:
```bash
helm upgrade my-nginx stable/nginx
```

### Steg 7: Ta bort en installation

Om du vill ta bort en applikation som du har installerat med Helm, kör:
```bash
helm uninstall <release-namn>
```
Till exempel:
```bash
helm uninstall my-nginx
```
Detta tar bort alla resurser som Helm installerade för den specifika applikationen.

---

## Sammanfattning

Helm är ett oumbärligt verktyg för att hantera applikationer på Kubernetes. Det gör det enkelt att installera, uppdatera och hantera applikationer genom att använda charts. Helm sparar tid och resurser genom att erbjuda ett strukturerat och återanvändbart sätt att hantera komplexa applikationer.

Följ stegen ovan för att installera Helm, lägga till repositories, söka efter och installera charts, samt hantera dina applikationer i Kubernetes.