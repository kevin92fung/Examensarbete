# Installation av OpenMediaVault på Debian/Raspberry Pi 5

Denna guide beskriver hur du installerar och konfigurerar OpenMediaVault (OMV) samt sätter upp en RAID-konfiguration och delar data via NFS och SMB. Följ stegen noggrant.

## Förutsättningar
- Alla kommandon körs som root. Logga in som root med följande kommando:

```bash
su -
```

Ange sedan root-lösenordet.

---

## Steg 1: Installera OpenMediaVault

### 1. Installera GNUPG
```bash
apt-get install --yes gnupg
```

### 2. Hämta och installera OMVs arkivnyckel
```bash
wget --quiet --output-document=- https://packages.openmediavault.org/public/archive.key | gpg --dearmor --yes --output "/usr/share/keyrings/openmediavault-archive-keyring.gpg"
```

### 3. Lägg till OMVs paketförråd
```bash
cat <<EOF >> /etc/apt/sources.list.d/openmediavault.list
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public sandworm main
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages sandworm main
## Uncomment the following line to add software from the proposed repository.
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public sandworm-proposed main
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages sandworm-proposed main
EOF
```

### 4. Installera OMV-paket
```bash
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault
```

### 5. Fyll databasen med befintliga inställningar
```bash
omv-confdbadm populate
```

### 6. Uppdatera nätverkskonfigurationen
```bash
omv-salt deploy run systemd-networkd
```

---

## Steg 2: Lägg till och konfigurera diskar

1. **Lägg till diskar**  
   - Lägg till fysiska diskar (eller via Hyper-V).

2. **Logga in på OMV**  
   - Använd webbläsaren och logga in på OMV med:
     - **Användarnamn:** `admin`
     - **Lösenord:** `openmediavault`

3. **Installera RAID-plugin**  
   - Gå till `System > Plugins` och installera `openmediavault-md`.

4. **Formatera diskar**  
   - Gå till `Storage > Disks`, välj dina diskar (t.ex. `/dev/sdb-sde`) och formatera dem.

5. **Skapa RAID**  
   - Gå till `Storage > RAID Management`, klicka på `+`, välj **RAID 5**, och markera diskarna.

6. **Skapa ett filsystem**  
   - Gå till `Storage > Filesystems`, klicka på `+`, välj **EXT4**, välj din RAID och klicka på `Play` för att montera.

7. **Skapa en delad mapp**  
   - Gå till `Storage > Shared Folders`, klicka på `+`, och välj filsystemet.

---

## Steg 3: Aktivera delning via NFS och SMB

1. **Aktivera NFS och SMB**  
   - Gå till `Services > NFS` och `Services > SMB`, aktivera båda tjänsterna.

2. **Lägg till delad mapp**  
   - Under respektive tjänst, lägg till den delade mappen från `Shared Folders`.

3. **Konfigurera NFS**  
   - Lägg till en klient som kan ansluta (t.ex. `<192.168.xxx.0/24>` för att tillåta hela nätverket).

4. **Skapa användare**  
   - Skapa en användare med lösenord och ge rättigheter (read/write) till den delade mappen.

---

## Steg 4: Justera rättigheter

Logga in via SSH på OMV-servern och ändra rättigheter för din mapp:
```bash
chown -R nobody:nogroup /srv/<din nya raid>/<mappens namn>
chmod -R 777 /srv/<din nya raid>/<mappens namn>
```

---

## Steg 5: Anslut till din NAS

### För Linux:
1. Skapa en mapp att montera NAS-enheten i:
   ```bash
   mkdir <katalog för mount>
   ```
2. Montera NAS-enheten:
   ```bash
   mount <IP-adress>:/export/<mappens namn> <katalog för mount>
   ```

### För Windows:
1. Öppna Utforskaren.
2. Ange i adressfältet:
   ```
   \\<IP-adress>\<mappens namn>
   ```
3. Ange användarnamn och lösenord.



[⬆️ Till toppen](#top)



## Byta IP på NAS-enheten
För att ändra IP-adressen på NAS-enheten:
```bash	
sudo nano /etc/network/interfaces
```
Uppdatera konfigurationsfilen med din nya IP-adress.
```bash
auto eth0
iface eth0 inet static
  address <192.168.xxx.xxx>
  netmask 255.255.255.0
  gateway <192.168.xxx.1>
  dns-nameservers 8.8.8.8 8.8.4.4
```
Spara och starta om nätverksgränssnittet:
```bash
sudo systemctl restart networking
```
[⬆️ Till toppen](#top)

# Konfigurera brandväggen
## **Steg 1: Konfigurera statiska portar för NFS**
NFS använder flera tjänster som behöver statiska portar för att undvika konflikt med dynamiska portar. Detta gör brandväggskonfigurationen enklare.

### **1.1 Redigera konfigurationsfil för NFS**
Öppna och redigera filen `/etc/default/nfs-kernel-server`:

```bash
sudo nano /etc/default/nfs-kernel-server
```

Lägg till följande rader (eller uppdatera om de redan finns):

```bash
MOUNTD_PORT=20048
STATD_PORT=32765
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32803
```

### **1.2 Uppdatera tjänsterna**
Öppna filen `/etc/services` och verifiera eller lägg till följande:

```plaintext
nfs             2049/tcp                          # NFS
nfs             2049/udp                          # NFS
mountd          20048/tcp                         # Mount daemon
statd           32765/tcp                         # Statd daemon
statd           32765/udp                         # Statd daemon
lockd           32803/tcp                         # Lockd daemon
lockd           32803/udp                         # Lockd daemon
```

Spara och stäng filen.

### **1.3 Starta om tjänsterna**
För att tillämpa ändringarna, starta om NFS och relaterade tjänster:

```bash
sudo systemctl restart nfs-kernel-server
sudo systemctl restart rpcbind
```

---

## **Steg 2: Konfigurera UFW-brandväggen**
För att säkerställa att brandväggen tillåter nödvändiga tjänster och portar, konfigurera UFW enligt följande.

### **2.1 Öppna portar för NFS**
Öppna alla portar som behövs för NFS:

```bash
sudo ufw allow from 192.168.3.0/24 to any port 2049    # NFS
sudo ufw allow from 192.168.3.0/24 to any port 20048   # mountd
sudo ufw allow from 192.168.3.0/24 to any port 32765   # statd
sudo ufw allow from 192.168.3.0/24 to any port 32803   # lockd
```

### **2.2 Öppna portar för SSH**
SSH använder standardport **22**. Tillåt endast trafik från ditt lokala nätverk:

```bash
sudo ufw allow from 192.168.3.0/24 to any port 22
```

### **2.3 Öppna portar för SMB**
SMB använder flera portar. Öppna dem så här:

```bash
sudo ufw allow from 192.168.3.0/24 to any port 137    # NetBIOS Name Service
sudo ufw allow from 192.168.3.0/24 to any port 138    # NetBIOS Datagram Service
sudo ufw allow from 192.168.3.0/24 to any port 139    # NetBIOS Session Service
sudo ufw allow from 192.168.3.0/24 to any port 445    # Microsoft-DS
```

### **2.4 Öppna portar för HTTP**
HTTP och HTTPS använder standardportarna **80** och **443**. Öppna dem så här:

```bash
sudo ufw allow from 192.168.3.0/24 to any port 80     # HTTP
sudo ufw allow from 192.168.3.0/24 to any port 443    # HTTPS
```

### **2.5 Kontrollera UFW-regler**
När alla portar är öppnade kan du kontrollera att reglerna är korrekt tillämpade:

```bash
sudo ufw status verbose
```

---

## **Steg 3: Testa anslutningar**
Efter att ha konfigurerat brandväggen och tjänsterna:

1. **NFS:** Testa att montera NFS-delningen från en klient:
   ```bash
   sudo mount -t nfs -o vers=4 192.168.3.210:/export/Shared-drive /mnt/NAS
   ```

2. **SSH:** Testa att ansluta via SSH:
   ```bash
   ssh user@192.168.3.210
   ```

3. **SMB:** Testa att ansluta till SMB-delningar:
   ```bash
   smbclient -L //192.168.3.210 -U username
   ```

4. **HTTP:** Öppna en webbläsare och navigera till:
   ```
   http://192.168.3.210
   ```

---

## **Sammanfattning av brandväggsregler**
### Öppnade portar:
| **Tjänst**  | **Port(ar)**             | **Beskrivning**                          |
|-------------|--------------------------|------------------------------------------|
| NFS         | 2049, 20048, 32765, 32803 | Huvudportar och relaterade tjänster      |
| SSH         | 22                       | Fjärranslutning                         |
| SMB         | 137, 138, 139, 445       | SMB-tjänster för fil- och skrivardelning |
| HTTP/HTTPS  | 80, 443                  | Webbtjänster                             |

[⬆️ Till toppen](#top)