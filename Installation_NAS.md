# Installation av NAS funktioner på debian
## Förberedelser
- 4-5 st diskar kopplade till enheten
- root åtkomst, allt görs som root
## Installera nödvändiga paket och lägg till användare som sudo
Byt ut `<användarnamn>` med användarnamnet du valde under installationen
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

## Skapa RAID 5
Bekräfta att diskarna är anslutna:
```bash
lsblk
```
listas upp som sdb, sdc, sdd, sde, sdf, sdg.... Kolla exempel:
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
Skapa RAID 5 med 4 diskar (byt ut diskarna om nödvändigt):
```bash
mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```
Bekräfta att det ser ut som följande med `lsblk`:
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
Spara RAID-konfigurationen så att den monteras vid omstart:
```bash
mdadm --detail --scan --verbose >> /etc/mdadm/mdadm.conf
update-initramfs -u
```

Denna rad ska vara i `/etc/mdadm/mdadm.conf`
```bash
ARRAY /dev/md0 level=raid5 num-devices=4 metadata=1.2 name=NAS:0 UUID=8cf1ebb5:820ac512:f2f1ba92:a1aa4342
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
```
Bekräfta att RAID-volymen är skapad som `md0`, använd `lsblk` för att bekräfta. Se exempel:
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
echo '/dev/md0 /NAS ext4 defaults 0 0' >> /etc/fstab
systemctl daemon-reload
mount -a
```
Starta om maskinen för att se till att RAID-volymen skapas och monteras efter omstart.
```bash	
reboot
```
Bekräfta med `lsblk` att RAID-volymen är monterad. Se exempel:
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

---

## Skapa NFS-delning

