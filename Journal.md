## Journal för exjobb

### Vecka 1
#### Måndag
- Installerade Debian och konfigurerade OpenMediaVault som NAS.
- Skrev en guide för installation och konfiguration av OpenMediaVault.

#### Tisdag
- Installerade k3s (Kubernetes).
- Började skriva en guide om installationen av k3s.

#### Onsdag
- Installerade k3s med virtuellt IP för lastbalansering och använde NAS som centraliserad lagring.
- Uppdaterade min guide om k3s-installation.

#### Torsdag
- Installerade om k3s med Kube-VIP som lastbalanserare.
- Installerade Longhorn som centraliserad lagring och läste på om Longhorn.
- Lyckades nå Longhorn UI.
- Installerade Portainer och konfigurerade replikerat data över alla noder.
- Stötte på problem med backup från Longhorn till NFS.
- Skrev en guide för installation av Longhorn.

#### Fredag
- Fördjupade mig i NAS-koncept och byggde en NAS-lösning direkt på Debian via terminal.
- Skrev en guide om att sätta upp Portainer.
- Uppdaterade min guide om RAID-konfiguration i Debian och NAS-skapande.
- Lyckades konfigurera Longhorn-backup till NFS-servern.
- Börjat kolla på hur Nextclouds ska installeras som en Pod

### Lördag
- Började läsa på om Helm för att kunna använda vid deploy av applikationer i Kubernetes.

### Söndag
- Fortsatte att läsa på om Helm och Kubernetes.
- Läste på och om Kube-VIP, hur man konfigurerar det och hur det fungerar med att använda det som lastbalanserare och tilldela virtuella IP-adresser. Skrev även en guide om detta.

---

## Vecka 2
### Måndag
- Genomgång av Examensarbetet med handledare.
- Installerade om klustret så den är Highly Available, använder kube-vip som lastbalanserare och Longhorn som centraliserad lagring.
- Fick problem med att NAS inte fungerade efter omstart.

### Tisdag
- Installerar om NAS för klustert och säkerställer att raid monteras efter omstart.
- Skriver guide om installation av NAS.
- Installerade Helm och skrev guide
- Försökte installera Portainer med helm, men fick problem med kluster ip och context
- Skrev skript för att snabbare kunna installera K3S Master och Worker noder

### Onsdag
- Installerade kubectl på windows för att kunna använda kubectl i windows mot klustret.
- Skrev guide om hur man installerar kubectl på windows och kopplar mot kubernetes klustret
- Installation av WSL (Windows Subsystem for Linux) för att hantera klustret och kubectl.



















---
# Presentation
### **Förslag på struktur för 15 minuter**

1. **Introduktion (2 minuter)**  
   - **Vad är projektet?** Ge en kort bakgrund.  
   - **Syfte och mål:** Vad vill du uppnå med projektet?  
   - T.ex. "Jag har byggt en skalbar och flexibel Kubernetes-miljö för att hantera en NAS med flera applikationer som Nextcloud, Jellyfin och Pi-hole."

2. **Visa Nginx-scaling (3 minuter)**  
   - Visa en praktisk demo där du spinner upp flera **Nginx Pods** och hur de hanteras.  
   - Fokusera på:  
     - **Hur skalningen fungerar.**  
     - Om möjligt, visa att det påverkar en faktisk tjänst, t.ex. en enkel webbsida.  
   - Detta ger en "wow-effekt" och visar att systemet fungerar.

3. **Topologi och dashboard (3 minuter)**  
   - Visa en bild av topologin och förklara kort de viktiga delarna:  
     - Kubernetes-kluster med **k3s**.  
     - NAS som lagringslösning.  
     - Anslutna tjänster.  
   - Hoppa snabbt till din dashboard (t.ex. Portainer eller Grafana) och visa realtidsdata om klustret.  
     - Visa Pods, nätverkstrafik, och lagring på ett överskådligt sätt.

4. **Longhorn/NAS (4 minuter)**  
   - Förklara hur Longhorn hanterar lagringen och varför det är viktigt.  
   - Visa kort hur RWX-volymer används och kopplas till applikationerna.  
   - Om möjligt, visa hur din NAS fungerar, t.ex. genom att öppna Nextcloud eller en NFS-delning.

5. **Helm (2 minuter)**  
   - Beskriv kort hur du använder Helm för att installera och hantera applikationer.  
   - Visa ett YAML-exempel och resultatet av ett Helm-kommando, t.ex. `helm install`.  
   - Detta är mest för att visa att du använder verktyg som förenklar hanteringen.

---

### **Tips för 15 minuter**
- **Fokusera på demos och visualiseringar:** Teori är bra, men en live-demo eller visuella topologier är mer engagerande på kort tid.  
- **Prioritera:** Om tiden blir knapp, lägg mer tid på Nginx-scaling och topologin än på detaljer om Helm.  
- **Ha en reservplan:** Om en demo misslyckas, ha en skärmdump eller inspelning redo.  

---

### **Reviderad struktur**
- **Introduktion (2 min)**: Projektmål och sammanfattning.  
- **Nginx-demo (4 min)**: Live-scaling.  
- **Topologi och dashboard (3 min)**: Visa kluster och realtidsövervakning.  
- **Longhorn/NAS (4 min)**: Lagringslösning och applikationsexempel.  
- **Avslutning (2 min)**: Helm och kort summering av projektet.

