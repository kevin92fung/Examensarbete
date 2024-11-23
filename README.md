### Arkitektur för Systemet - 3 Veckors Plan

#### **Översikt**
Projektet innebär att bygga en **Kubernetes-baserad infrastruktur** med hjälp av **Raspberry Pi 5-enheter** och en **Debian VM** som kör **OpenMediaVault** för lagring. I klustret ska tjänster som **Jellyfin/Plex**, **Sonarr**, **Radarr**, **Home Assistant**, **Pi-hole**, **Mealie**, **Nextcloud**, och en **dashboard** för att övervaka systemet distribueras. **Portainer** används för att hantera Docker-containrar och andra tjänster.

---

### **Systemarkitektur Översikt**

```
+-------------------------+            +------------------------+           +------------------------+
|   Kubernetes Master VM  | <------->  |     Raspberry Pi 5      | <----->   |     Raspberry Pi 5      |
|   (Debian VM)           |            |   Worker Node 1         |           |     Worker Node 2      |
|   (K8s Controller)      |            +------------------------+           +------------------------+
|   - Deploy, Scale,      |                                                     |
|     Manage Pods         |                                                     |
+-------------------------+            +-----------------------------------+    |
                                        |  Persistent Volumes (NFS or USB)  |    |
+-------------------------+            |                                   |    |
|      OpenMediaVault      | <--------> |                                   |    |
|     (NAS Storage)       |            |                                   |    |
|    - NFS Shares, Data   |            |                                   |    |
+-------------------------+            +-----------------------------------+    |
                                        |                                   |    |
                                        v                                   v    v
                                +---------------------+       +---------------------+
                                | Kubernetes Pods     |       | Persistent Storage   |
                                | - Jellyfin/Plex      |       | - OpenMediaVault     |
                                | - Radarr             |       | - Mealie             |
                                | - Sonarr             |       | - Nextcloud          |
                                | - Home Assistant     |       |                     |
                                | - Pi-hole            |       |                     |
                                | - Dashboard          |       |                     |
                                | - Portainer          |       |                     |
                                +---------------------+       +---------------------+
                                         |
                                         v
                                 +---------------------+
                                 |  Kubernetes Service |
                                 | - Load Balancer     |
                                 +---------------------+

```

---

### Syfte med Projektet

1. **Skalbar Infrastruktur**: 
   Bygga en **skalbar** och **flexibel** applikationsinfrastruktur med Raspberry Pi och Debian VM som kan växa i takt med behovet.

2. **Centraliserad Lagring**:
   Använda **OpenMediaVault** för att tillhandahålla **NAS-lagring** för alla applikationer i Kubernetes-klustret.

3. **Effektiv Hantering**:
   Hantera och övervaka applikationer och tjänster via en **dashboard** och **Portainer**.

4. **Automatisering**:
   Skapa en **automatiserad** lösning med hjälp av Kubernetes för att distribuera och hantera applikationerna på klustret.

---

### Mål

1. **Skalbarhet**: 
   Skapa ett system som enkelt kan skalas upp genom att lägga till fler Raspberry Pi-enheter när det behövs.

2. **Automatisering och Enkel Hantering**: 
   Använd Kubernetes och **Portainer** för att effektivisera hanteringen av tjänster och containrar.

3. **Centraliserad Lagring**:
   Säkerställa att lagringen är säker, enkel att använda och skalbar via **OpenMediaVault** och **Persistent Volumes**.

4. **Integration av Smarta Hem**:
   Integrera tjänster som **Home Assistant** för att hantera smarta enheter och **Pi-hole** för nätverksblockering av annonser.

---

### Planering - 3 Veckor

#### **Vecka 1: Infrastruktur och Kubernetes Setup**
- **Installera Kubernetes** på både **Debian VM** och **Raspberry Pi-enheter**.
- Konfigurera **Kubernetes-klustret** och säkerställ att noderna kan kommunicera korrekt.
- Installera **OpenMediaVault** på VM för att hantera NAS-lagring och skapa NFS-delningar.
- Skapa en **Persistent Volume (PV)** i Kubernetes som använder NFS från **OpenMediaVault** för att lagra data.

#### **Vecka 2: Installera Applikationer och Tjänster**
- Distribuera applikationerna i **Kubernetes-pods**:
  - **Jellyfin/Plex** för mediaserver.
  - **Sonarr och Radarr** för filhantering och automation av nedladdningar.
  - **Home Assistant** för att hantera smarta enheter.
  - **Pi-hole** för annonsblockering.
  - **Mealie** för att lagra recept.
  - **Nextcloud** för privat molnlagring.
  - **Portainer** för hantering av containrar.
  - **Dashboard** för övervakning och hantering av systemet.

#### **Vecka 3: Nätverk, Test och Dokumentation**
- Konfigurera **Kubernetes Services** för att hantera trafikflödet mellan applikationer och exponera vissa tjänster utanför klustret via **Load Balancer**.
- **Testa systemet** genom att lägga till noder och säkerställa att skalning fungerar som förväntat.
- Skriv **dokumentation** för installation, drift och hantering av systemet för att säkerställa långsiktig användning och underhåll.

---

### Slutsats

Detta projekt syftar till att bygga en **robust** och **skalbar** applikationsinfrastruktur för att hantera filmer, media, smarta hem-tjänster och lagring genom användning av **Kubernetes**, **OpenMediaVault** och en rad viktiga tjänster som **Jellyfin**, **Sonarr**, **Radarr**, **Home Assistant** och **Nextcloud**. Projektet ska vara klart inom tre veckor och ge en funktionell, övervakad och automatiserad lösning som kan växa i takt med att nya Raspberry Pi-enheter läggs till.