# Installation av NAS funktioner på debian
## Förberedelser
- 4-5 st diskar kopplade till enheten
- root åtkomst, allt görs som root

## Innehåll
- [Installation av nödvändiga paket](#installation-av-nas-funktioner-på-debian)
- [Skapa RAID 5](#skapa-raid-5)
- [Skapa NFS-delning](#skapa-nfs-delning)
- [Skapa SMB-delning](#skapa-smb-delning)
- [Testa Delningen](#testa-delning)
- [Script för hela installationen](#yolo-style-installations-skript)

## Installera nödvändiga paket och lägg till användare som sudo
**Byt ut `<användarnamn>` med användarnamnet du valde under installationen**
```bash
#Definera variabel för användarnamn
username="<användarnamn>" # byt ut med användarnamnet du valde under installationen

#Installera nödvändiga paket
apt install nfs-kernel-server samba samba-common-bin sudo mdadm

#Lägg till användaren i sudo-gruppen
usermod -aG sudo $username

#Redigera sudoers-filen för att ge användaren sudo-rättigheter
echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
```
[⬆️ Till toppen](#top)

---
## Skapa RAID 5
**Bekräfta att diskarna är anslutna:**
```bash
lsblk
```
**Diskarna bör listas upp som sdb, sdc, sdd, sde, sdf, sdg.... Kolla exempel:**
```bash
root@NAS:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   127G  0 disk
├─sda1   8:1    0   512M  0 part /boot/efi
├─sda2   8:2    0 125.5G  0 part /
└─sda3   8:3    0   976M  0 part [SWAP]
sdb      8:16   0    20G  0 disk
sdc      8:32   0    20G  0 disk
sdd      8:48   0    20G  0 disk
sde      8:64   0    20G  0 disk
sr0     11:0    1  1024M  0 rom
```
**Skapa RAID 5 med 4 diskar (byt ut diskarna om nödvändigt):**
```bash
mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```
**Bekräfta att det ser ut som följande med `lsblk`:**
```bash
root@NAS:~# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
sda      8:0    0   127G  0 disk
├─sda1   8:1    0   512M  0 part  /boot/efi
├─sda2   8:2    0 125.5G  0 part  /
└─sda3   8:3    0   976M  0 part  [SWAP]
sdb      8:16   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sdc      8:32   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sdd      8:48   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sde      8:64   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sr0     11:0    1  1024M  0 rom
```
**Spara RAID-konfigurationen så att den monteras vid omstart:**
```bash
mdadm --detail --scan --verbose >> /etc/mdadm/mdadm.conf
update-initramfs -u
```

**Denna rad ska vara i `/etc/mdadm/mdadm.conf`**
```bash
ARRAY /dev/md0 level=raid5 num-devices=4 metadata=1.2 name=NAS:0 UUID=8cf1ebb5:820ac512:f2f1ba92:a1aa4342
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
```
**Bekräfta att RAID-volymen är skapad som `md0`, använd `lsblk` för att bekräfta. Se exempel:**
```bash
root@NAS:~# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
sda      8:0    0   127G  0 disk
├─sda1   8:1    0   512M  0 part  /boot/efi
├─sda2   8:2    0 125.5G  0 part  /
└─sda3   8:3    0   976M  0 part  [SWAP]
sdb      8:16   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sdc      8:32   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sdd      8:48   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sde      8:64   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5
sr0     11:0    1  1024M  0 rom
```
**Formatera RAID-volymen:**
```bash
mkfs.ext4 /dev/md0
```
**Skapa en monteringspunkt:**
```bash
mkdir -p /NAS
```
**Lägg till RAID-volymen för automatisk montering vid omstart och montera:**
```bash
echo '/dev/md0 /NAS ext4 defaults 0 0' >> /etc/fstab
systemctl daemon-reload
mount -a
```
**Starta om maskinen för att se till att RAID-volymen skapas och monteras efter omstart.**
```bash	
reboot
```
**Bekräfta med `lsblk` att RAID-volymen är monterad. Se exempel:**
```bash
root@NAS:~# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
sda      8:0    0   127G  0 disk
├─sda1   8:1    0   512M  0 part  /boot/efi
├─sda2   8:2    0 125.5G  0 part  /
└─sda3   8:3    0   976M  0 part  [SWAP]
sdb      8:16   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5 /NAS
sdc      8:32   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5 /NAS
sdd      8:48   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5 /NAS
sde      8:64   0    20G  0 disk
└─md0    9:0    0    60G  0 raid5 /NAS
sr0     11:0    1  1024M  0 rom
```
[⬆️ Till toppen](#top)
---

## Skapa NFS-delning
**Skapa en NFS-delning till Longhorn backup**

**Börja med att skapa en katalog för delningenoch konfigurera katalogenens rättigheter:**
```bash
#Skapa katalogen
mkdir -p /NAS/longhorn-Backup

#Ändra ägare till katalogen till "nobody" och ändra rättigheter till 2777
chown nobody:nogroup /NAS/longhorn-Backup
chmod 2777 /NAS/longhorn-Backup

#Kontrollera att katalogen är skapad och att rättigheterna är korrekta
ls -ld /NAS/longhorn-Backup
```
**Rättigheterna ska se ut på detta sätt:**

`drwxrwsrwx 2 nobody nogroup 4096 Dec  3 12:45 /NAS/longhorn-Backup/`

**Lägg till NFS-delningen i `/etc/exports`:**
- 192.168.xxx.0/24tillåter att alla enheter inom det nätverket har tillgång till NFS Förklaring av NFS-inställningar:
- rw: Läst och skriv åtkomst
- sync: Synkronisering av skrivoperationer
- no_subtree_check: Förhindrar att NFS-servern kontrollerar katalogstrukturen vid export
- no_root_squash: Ger root-åtkomst för klienter
- insecure: Tillåter icke-säkra klienter
```bash
#Lägger till NFS delningen i /etc/exports (byt ut IP-adressen)
echo "/NAS/longhorn-Backup 192.168.3.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports

#Ladda om NFS-konfigurationen
exportfs -a

#Bekräfta att NFS-delningen är tillagd
exportfs -v

#Starta och aktivera NFS-tjänsten
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server
```
**Bekräftelse av NFS-delningen ska se ut på detta sätt:**

`192.168.3.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)`

[⬆️ Till toppen](#top)

---
## Skapa SMB-delning
**Skapa en SMB-delning till Longhorn backup**
```bash
#Lägger till delningen i smb.conf
cat <<EOF >> /etc/samba/smb.conf
[longhorn-Backup]
  path = /NAS/longhorn-Backup
  browseable = yes
  read only = no
  guest ok = yes
EOF

#Starta och aktivera SMB-tjänsten
systemctl restart smbd
systemctl enable smbd
```
[⬆️ Till toppen](#top)

## Testa delning

**NFS via annan Linux-enhet:**
```bash	
#Installera nfs-common
apt install nfs-common
#Skapa en monteringspunkt och montera NFS-delningskatalogen
mkdir -p /mnt/backup
mount <ip-till-nas>:/NAS/longhorn-Backup /mnt/backup

#Bekräfta att NFS-delningen är monterad
df -h
```

**SMB via Windows:**
Öppna Utforskaren och skriv in följande adress i adressfältet:

`\\<ip-till-NAS>`
Logga in med användare och lösenord från NAS-enheten.









# YOLO style installations skript
```bash
#!/bin/bash

```