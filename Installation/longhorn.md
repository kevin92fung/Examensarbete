Här är en uppdaterad guide för att installera Longhorn v1.7.2 och konfigurera en LoadBalancer för frontend:

## Installera Longhorn v.1.7.2
- Kolla på [Longhorns officiella hemsida](https://longhorn.io) för att se om en ny version finns tillgänglig.
- För frontend, ändra metadata i YAML-filen så att den matchar den version som installeras.

### Steg för installation och konfiguration:

```bash
# Installation av Longhorn v.1.7.2
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/deploy/longhorn.yaml

# Skapar en service för longhorn-ui (frontend)
cd ~
cat <<EOF > longhorn-frontend-loadbalancer.yaml
kind: Service
apiVersion: v1
metadata:
  labels:
    app.kubernetes.io/name: longhorn
    app.kubernetes.io/instance: longhorn
    app.kubernetes.io/version: v1.7.2
    app: longhorn-ui
  name: longhorn-frontend
  namespace: longhorn-system
spec:
  type: LoadBalancer
  ipFamilyPolicy: SingleStack
  loadBalancerIP: 192.168.3.230  # Specifik IP från din pool
  selector:
    app: longhorn-ui
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: null
EOF

# Applicerar frontend service och tar bort fil
kubectl apply -f longhorn-frontend-loadbalancer.yaml
rm longhorn-frontend-loadbalancer.yaml

# Verifierar att LoadBalancer är satt för frontend
kubectl -n longhorn-system get service longhorn-frontend
```

### Förklaring av stegen:
1. **Installation av Longhorn**:
   - `kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/deploy/longhorn.yaml` laddar ner och installerar Longhorn v1.7.2 i Kubernetes-klustret.
   
2. **Skapande av LoadBalancer-tjänst för frontend**:
   - Skapar en YAML-konfiguration för en tjänst av typ `LoadBalancer` för Longhorn UI (`longhorn-frontend`).
   - Tilldelar en statisk IP (`loadBalancerIP: 192.168.3.230`) från din pool för att exponera Longhorns frontend via en extern IP.

3. **Applicering av YAML-filen**:
   - Tjänsten appliceras på klustret via `kubectl apply`, och filen tas bort efteråt för att hålla systemet rent.

4. **Verifiering**:
   - Efter att tjänsten har applicerats, verifierar du att den externa IP:n (`loadBalancerIP`) har tilldelats via kommandot `kubectl -n longhorn-system get service longhorn-frontend`.
---
### Testa att komma åt Longhorn UI
1. **Öppna en webbläsare** och gå till den externa IP som tilldelats av LoadBalancer (t.ex., `http://192.168.3.230`).
   - Du bör kunna komma åt Longhorn UI om allt har konfigurerats korrekt.

### Sätt upp en NFS-backup till Longhorn
1. **Logga in på Longhorn UI**.
2. **Gå till Inställningar** genom att klicka på kugghjulsikonen i Longhorn UI.
3. **Välj Backup Target**.
4. **Ange NFS-serverns IP-adress och sökvägen till backupen**:
   - Fyll i fältet med NFS-serverns IP och sökvägen till delningen enligt formatet: 
   ```
   nfs://<NFS-server-IP>:/<sökväg-till-delning>
   ```
   Exempel:
   ```
   nfs://192.168.1.100:/mnt/backups
   ```

5. **Klicka på "Save"** för att spara inställningarna.

Longhorn kommer nu att använda den angivna NFS-servern som mål för backup. Se till att NFS-servern är korrekt konfigurerad och åtkomlig från Longhorns noder.