Här är en komplett guide för att konfigurera en NAS på Debian, inklusive installation och konfiguration av NFS, SMB, och RAID5, samt brandväggsinställningar:

---

## **Debian NAS Konfiguration**

### **Förberedelser:**
Alla kommandon utförs som `root`.

### **1. Installera Debian**
Installera Debian på din maskin enligt din vanliga metod (t.ex. med en live USB eller nätverksinstallation).

### **2. Byt IP-adress på servern**
Redigera nätverkskonfigurationen för att sätta en statisk IP-adress:

```bash
nano /etc/network/interfaces
```

Ändra följande rad till din statiska IP-konfiguration:

```bash
# The primary network interface
auto eth0
iface eth0 inet static
  address <ny-ip-address>   # För ett 24-nät
  netmask 255.255.255.0     # För ett 24-nät
  gateway <ip-till-router>
  dns-nameservers 8.8.8.8 8.8.4.4
```

Aktivera nya nätverksinställningar:

```bash
systemctl restart networking
```

Verifiera att den nya IP-adressen tillämpats:

```bash
ip addr
```

---

### **3. Installera sudo och skapa användare**
Installera `sudo` och lägg till en användare som kan köra sudo-kommandon:

```bash
apt install sudo
```

Lägg till en användare i `sudo`-gruppen:

```bash
usermod -AG sudo <användarnamn>
```

Redigera sudoers-filen för att ge användaren sudo-rättigheter:

```bash
visudo
```

Lägg till följande rad:

```bash
<användarnamn> ALL=(ALL:ALL) ALL
```

Testa användaren genom att köra:

```bash
sudo apt update
```

---

### **4. Lägg till diskar och skapa RAID 5**
Verktyg som behövs:

```bash
apt update && apt upgrade -y
apt install mdadm nfs-kernel-server samba samba-common-bin -y
```

Verifiera att diskarna är anslutna:

```bash
lsblk
```

Skapa RAID 5 med 4 diskar (byt ut diskarna om nödvändigt):

```bash
mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

Bekräfta RAID-konfigurationen:

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

Spara RAID-konfigurationen så att den monteras vid omstart:

```bash
mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf
update-initramfs -u
```

Formatera RAID-volymen:

```bash
mkfs.ext4 /dev/md0
```

Skapa en monteringspunkt:

```bash
mkdir -p /NAS
```

Lägg till RAID-volymen för automatisk montering vid omstart och montera:

```bash
echo '/dev/md0 /NAS ext4 defaults 0 0' | tee -a /etc/fstab
mount -a
```

Ändra rättigheter på NAS-katalogen:

```bash
chown -R nobody:nogroup /NAS
chmod -R 2777 /NAS
```

---

### **5. Dela NAS via NFS**
Skapa en katalog för delning (t.ex. för backup):

```bash
mkdir -p /NAS/backup
```

Redigera NFS-konfigurationsfilen för att dela katalogen:

```bash
nano /etc/exports
```

Lägg till följande rad:

```bash
/NAS/backup <ip-till-enhet-som-ska-nå-nfs>/24(rw,sync,no_subtree_check,no_root_squash,insecure)
```

Förklaring av NFS-inställningar:
- `rw`: Läst och skriv åtkomst
- `sync`: Synkronisering av skrivoperationer
- `no_subtree_check`: Förhindrar att NFS-servern kontrollerar katalogstrukturen vid export
- `no_root_squash`: Ger root-åtkomst för klienter
- `insecure`: Tillåter icke-säkra klienter

Ladda om NFS-konfigurationen:

```bash
exportfs -ra
```

Starta och aktivera NFS-servern:

```bash
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server
```

---

### **6. Dela NAS via SMB**
Redigera Samba-konfigurationsfilen för att dela en katalog:

```bash
nano /etc/samba/smb.conf
```

Lägg till följande sektion för delning:

```bash
[Namnet på delning]
  path = /NAS/backup
  browsable = yes
  read only = no
  guest ok = yes
```

Starta och aktivera SMB-tjänsten:

```bash
systemctl start smbd
systemctl enable smbd
```

---

### **7. Testa delningen**
#### **NFS via annan Linux-enhet:**
Installera `nfs-common`:

```bash
apt install nfs-common
```

Skapa en monteringspunkt och montera NFS-delningskatalogen:

```bash
mkdir -p /mnt/backup
mount <ip-till-nas>:/NAS/backup /mnt/backup
```

#### **SMB via Windows:**
Öppna Utforskaren och skriv in följande adress i adressfältet:

```bash
\\<ip-till-NAS>
```

Logga in med användare och lösenord från NAS-enheten.

---

### **8. Konfigurera brandväggsregler**
#### **Steg 1: Statiska portar för NFS**
Redigera konfigurationsfilen `/etc/default/nfs-kernel-server`:

```bash
nano /etc/default/nfs-kernel-server
```

Lägg till följande rader:

```bash
MOUNTD_PORT=20048
STATD_PORT=32765
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32803
```

Verkställa ändringarna:

```bash
sudo systemctl restart nfs-kernel-server
sudo systemctl restart rpcbind
```

#### **Steg 2: UFW-brandvägg**
Öppna nödvändiga portar för NFS och SMB:

```bash
sudo ufw allow from 192.168.3.0/24 to any port 2049    # NFS
sudo ufw allow from 192.168.3.0/24 to any port 20048   # mountd
sudo ufw allow from 192.168.3.0/24 to any port 32765   # statd
sudo ufw allow from 192.168.3.0/24 to any port 32803   # lockd

sudo ufw allow from 192.168.3.0/24 to any port 137    # NetBIOS
sudo ufw allow from 192.168.3.0/24 to any port 138    # NetBIOS
sudo ufw allow from 192.168.3.0/24 to any port 139    # NetBIOS
sudo ufw allow from 192.168.3.0/24 to any port 445    # SMB
sudo ufw allow from 192.168.3.0/24 to any port 22     # SSH
```

Kontrollera UFW-reglerna:

```bash
sudo ufw status verbose
```

---

Nu har du en fungerande NAS med både NFS och SMB-delningsmöjligheter, samt RAID5 för dataskydd.