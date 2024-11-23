### Fullständig guide: Skapa en RAID 50-array i Ubuntu på Hyper-V

Den här guiden förklarar hur du skapar en **RAID 50-array** på Ubuntu med sex diskar. Vi går igenom allt från att identifiera diskar till att konfigurera en beständig RAID.

---

## **Steg 1: Verifiera diskarna**

1. När du har lagt till diskar, kontrollera att systemet känner igen dem:
   ```bash
   lsblk
   ```
   Exempel på output:
   ```
   NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
   sda      8:0    0   127G  0 disk
   ├─sda1   8:1    0     1G  0 part /boot/efi
   ├─sda2   8:2    0     2G  0 part /boot
   └─sda3   8:3    0 123.9G  0 part /
   sdb      8:16   0    10G  0 disk
   sdc      8:32   0    10G  0 disk
   sdd      8:48   0    10G  0 disk
   sde      8:64   0    10G  0 disk
   sdf      8:80   0    10G  0 disk
   sdg      8:96   0    10G  0 disk
   ```

   I detta exempel är `/dev/sdb`, `/dev/sdc`, `/dev/sdd`, `/dev/sde`, `/dev/sdf` och `/dev/sdg` diskarna som ska användas för RAID.

---

## **Steg 2: Installera `mdadm`**

1. Uppdatera paketlistan:
   ```bash
   sudo apt update
   ```
2. Installera `mdadm`:
   ```bash
   sudo apt install mdadm
   ```

---

## **Steg 3: Skapa RAID 5-arrayer**

Dela de sex diskarna i två grupper med tre diskar i varje grupp. Varje grupp skapar en RAID 5-array.

### Skapa den första RAID 5-arrayen
1. Kör följande kommando:
   ```bash
   sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd
   ```
2. Verifiera att arrayen synkroniseras:
   ```bash
   cat /proc/mdstat
   ```

### Skapa den andra RAID 5-arrayen
1. Kör följande kommando:
   ```bash
   sudo mdadm --create /dev/md1 --level=5 --raid-devices=3 /dev/sde /dev/sdf /dev/sdg
   ```
2. Verifiera den andra arrayen:
   ```bash
   cat /proc/mdstat
   ```

---

## **Steg 4: Skapa en RAID 0-array från RAID 5-arrayerna**

När RAID 5-arrayerna har synkroniserats, kombinera dem till en RAID 0-array.

1. Skapa RAID 0-arrayen:
   ```bash
   sudo mdadm --create /dev/md2 --level=0 --raid-devices=2 /dev/md0 /dev/md1
   ```
2. Verifiera arrayen:
   ```bash
   cat /proc/mdstat
   ```

---

## **Steg 5: Formatera och montera RAID 50-arrayen**

1. Formatera RAID 50-arrayen med `ext4`:
   ```bash
   sudo mkfs.ext4 /dev/md2
   ```

2. Skapa en monteringspunkt:
   ```bash
   sudo mkdir /mnt/raid50
   ```

3. Montera RAID-arrayen:
   ```bash
   sudo mount /dev/md2 /mnt/raid50
   ```

4. Verifiera monteringen:
   ```bash
   df -h
   ```

---

## **Steg 6: Gör RAID-arrayen beständig**

För att säkerställa att RAID 50-arrayen är tillgänglig efter en omstart:

1. Hämta UUID för RAID 50-arrayen:
   ```bash
   sudo blkid /dev/md2
   ```

2. Redigera filen `fstab` för att lägga till arrayen:
   ```bash
   sudo nano /etc/fstab
   ```
   Lägg till följande rad (ersätt `din-uuid-här` med den faktiska UUID):
   ```
   UUID=din-uuid-här /mnt/raid50 ext4 defaults 0 0
   ```

3. Testa ändringarna i `fstab`:
   ```bash
   sudo mount -a
   ```

---

## **Steg 7: Spara RAID-konfigurationen**

1. Spara RAID-konfigurationen i `/etc/mdadm/mdadm.conf`:
   ```bash
   sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
   ```

2. Uppdatera `initramfs` för att inkludera RAID-konfigurationen:
   ```bash
   sudo update-initramfs -u
   ```

---

## **Steg 8: Verifiera RAID-inställningen**

1. Kontrollera RAID-detaljerna:
   ```bash
   sudo mdadm --detail /dev/md2
   ```
2. Se till att allt fungerar efter en omstart:
   ```bash
   sudo reboot
   ```
3. Efter omstart, bekräfta att RAID-arrayen är monterad:
   ```bash
   df -h
   cat /proc/mdstat
   ```

To install Docker and Nextcloud on an Ubuntu Server, follow these steps:

### 1. Install Docker
Start by updating your system packages and installing Docker.

1. Update the package list:
   ```bash
   sudo apt update
   ```

2. Install the necessary dependencies:
   ```bash
   sudo apt install apt-transport-https ca-certificates curl software-properties-common
   ```

3. Add Docker’s official GPG key:
   ```bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

4. Set up the stable Docker repository:
   ```bash
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. Update the package index again:
   ```bash
   sudo apt update
   ```

6. Install Docker:
   ```bash
   sudo apt install docker-ce
   ```

7. Verify that Docker is installed and running:
   ```bash
   sudo systemctl status docker
   ```

   To allow running Docker commands without `sudo`, add your user to the `docker` group:
   ```bash
   sudo usermod -aG docker $USER
   ```

   Then log out and back in for the changes to take effect.

### 2. Install Docker Compose (Optional but recommended for easy management of multi-container setups)

1. Download Docker Compose:
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   ```

2. Make it executable:
   ```bash
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Verify the installation:
   ```bash
   docker-compose --version
   ```

### 3. Install Nextcloud using Docker

1. Create a directory for your Nextcloud files:
   ```bash
   mkdir -p ~/nextcloud
   cd ~/nextcloud
   ```

2. Create a `docker-compose.yml` file:
   ```bash
   nano docker-compose.yml
   ```

3. Add the following content to `docker-compose.yml`:
   ```yaml
   version: '3'

   services:
     nextcloud:
       image: nextcloud
       restart: always
       ports:
         - 8080:80
       volumes:
         - nextcloud:/var/www/html
       environment:
         MYSQL_PASSWORD: example
         MYSQL_DATABASE: nextcloud
         MYSQL_USER: nextcloud
         MYSQL_HOST: db
       depends_on:
         - db

     db:
       image: mariadb
       restart: always
       environment:
         MYSQL_ROOT_PASSWORD: example
         MYSQL_PASSWORD: example
         MYSQL_DATABASE: nextcloud
         MYSQL_USER: nextcloud
       volumes:
         - db:/var/lib/mysql

   volumes:
     nextcloud:
     db:
   ```

   This configuration sets up two containers:
   - **Nextcloud**: The Nextcloud application.
   - **db**: A MariaDB container for the Nextcloud database.

4. Start the containers:
   ```bash
   docker-compose up -d
   ```

5. Check if everything is running:
   ```bash
   docker-compose ps
   ```

6. Access Nextcloud by opening a browser and navigating to:
   ```
   http://<your-server-ip>:8080
   ```

7. Follow the web setup for Nextcloud. You can enter the database details (use `nextcloud` as the database name and `nextcloud` for both the user and password).

---

This should get Docker and Nextcloud running on your Ubuntu server. Let me know if you need further assistance!
