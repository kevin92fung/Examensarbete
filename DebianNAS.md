# Förbered lagring för NAS

Denna guide visar hur du sätter upp en RAID 5-konfiguration med 5 diskar på en Ubuntu-server och delar den via NFS och SMB, samt hur du öppnar rätt portar i brandväggen med `ufw`.

---

## Förberedelser för NAS

### 1. Lägg till 4-5 diskar till enheten
Fysiskt anslut eller konfigurera dina diskar till enheten.

### 2. Verifiera att diskarna är på plats
Kontrollera att alla diskar är anslutna genom att köra:
```bash
lsblk
```

**Exempeloutput**:
```
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda       8:0    0   100G  0 disk
sdb       8:16   0   500G  0 disk
sdc       8:32   0   500G  0 disk
sdd       8:48   0   500G  0 disk
sde       8:64   0   500G  0 disk
sdf       8:80   0   500G  0 disk
```

### 3. Uppdatera och installera nödvändiga verktyg
Kör följande kommandon för att uppdatera systemet och installera RAID-, NFS- och SMB-verktyg:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install mdadm nfs-kernel-server samba samba-common-bin -y
```

---

## Installera och konfigurera UFW

### 4. Installera och verifiera UFW
För att säkerställa att `ufw` är installerat, kör följande kommando:
```bash
sudo apt install ufw -y
```

Om `ufw` redan är installerat, kan du kontrollera dess status med:
```bash
sudo ufw status
```

### 5. Aktivera brandväggen
Om brandväggen inte är aktiverad, kör följande kommando för att aktivera den:
```bash
sudo ufw enable
```

---

## Skapa RAID 5-konfiguration

### 6. Skapa RAID 5
För fem diskar, kör:
```bash
sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=5 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf
```

### 7. Bekräfta RAID-konfigurationen
Kör följande kommandon för att verifiera statusen:
```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

### 8. Spara RAID-konfigurationen
Skapa en konfigurationsfil så att RAID monteras automatiskt vid omstart:
```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

---

## Förbered RAID-volymen

### 9. Formatera RAID-volymen
Formatera RAID-enheten med ext4:
```bash
sudo mkfs.ext4 /dev/md0
```

### 10. Skapa en monteringspunkt
Skapa en katalog för RAID-volymen:
```bash
sudo mkdir /mnt/raid
```

### 11. Lägg till RAID-enheten i `/etc/fstab`
Lägg till följande rad för automatisk montering:
```bash
echo '/dev/md0 /mnt/raid ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo mount -a
```

---

## Dela RAID-volymen via NFS

### 12. Ändra rättigheter för RAID-volymen
Gör katalogen tillgänglig för NFS:
```bash
sudo chown nobody:nogroup /mnt/raid
```

### 13. Konfigurera NFS-exporter
Öppna konfigurationsfilen:
```bash
sudo nano /etc/exports
```
Lägg till följande rad (ändra IP-adressen till din nätverksadress):
```
/mnt/raid    <192.168.xxx.0/24>(rw,sync,no_subtree_check)
```

### 14. Ladda om NFS-konfigurationen
Ladda om konfigurationen:
```bash
sudo exportfs -ra
```

### 15. Starta och aktivera NFS-servern
Kör följande kommandon:
```bash
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

---

## Dela RAID-volymen via SMB

### 16. Konfigurera SMB-delning
Skapa en delning i Samba genom att öppna konfigurationsfilen:
```bash
sudo nano /etc/samba/smb.conf
```

Lägg till följande sektion i filen:
```
[raid-share]
   path = /mnt/raid
   browsable = yes
   read only = no
   guest ok = yes
```

### 17. Starta om Samba-tjänsten
Starta om Samba-tjänsten för att tillämpa konfigurationen:
```bash
sudo systemctl restart smbd
```

### 18. Aktivera Samba att starta vid boot
För att säkerställa att Samba startar vid omstart:
```bash
sudo systemctl enable smbd
```

---

## Öppna portar för NFS och SMB med UFW

### 19. Öppna portar för NFS och SMB i brandväggen
För att tillåta NFS- och SMB-trafik från ditt nätverk (ändra `<192.168.xxx.0/24>` till din nätverksadress), kör följande kommandon:

#### För NFS:
```bash
sudo ufw allow from 192.168.xxx.0/24 to any port 2049      # NFS
sudo ufw allow from 192.168.xxx.0/24 to any port 111       # RPC (portmapper)
sudo ufw allow from 192.168.xxx.0/24 to any port 20048     # NFS lockd
```

#### För SMB:
```bash
sudo ufw allow from 192.168.xxx.0/24 to any port 445       # SMB
sudo ufw allow from 192.168.xxx.0/24 to any port 139       # NetBIOS (SMB)
```

### 20. Kontrollera brandväggens status
För att verifiera att brandväggsreglerna har applicerats korrekt, kör:
```bash
sudo ufw status
```

---

## Testa NFS och SMB-delningen

### 21. Testa NFS-delningen
Installera NFS-klient på en annan enhet:
```bash
sudo apt install nfs-common -y
```

Montera katalogen från servern:
```bash
sudo mount <server-ip>:/mnt/raid /mnt
```

### 22. Testa SMB-delningen
Från en Windows-enhet, öppna filhanteraren och skriv:
```
\\<server-ip>\raid-share
```

Byt `<server-ip>` mot din serverns IP-adress.

---

## Övervaka RAID, NFS och SMB

### 23. Kontrollera RAID-status
För att se RAID-status:
```bash
cat /proc/mdstat
```

### 24. Kontrollera NFS-loggar
För att övervaka NFS-servern:
```bash
sudo journalctl -u nfs-kernel-server
```

### 25. Kontrollera SMB-loggar
För att övervaka Samba-servern:
```bash
sudo journalctl -u smbd
```