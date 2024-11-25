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