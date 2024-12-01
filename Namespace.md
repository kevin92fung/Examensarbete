Här är en guide för att skapa en RAID-konfiguration på varje enskild Pi, montera NFS-delningar och skapa ett namespace med lastbalansering på en masterenhet. Jag kommer att använda **MergerFS** för att skapa namespace och distribuera lagringen mellan enheterna.

### **Steg 1: Skapa RAID på varje enskild Pi**

Först, på varje Raspberry Pi, ska vi skapa RAID-konfigurationer för att slå ihop flera diskar till en enhet. Vi använder **mdadm** för att skapa RAID.

1. **Installera mdadm på varje Pi:**
   På varje Pi-enhet, installera `mdadm` för att hantera RAID-konfigurationen.

   ```bash
   sudo apt update
   sudo apt install mdadm
   ```

2. **Skapa RAID-konfigurationer:**
   Här skapar vi ett RAID 1 (mirroring) på två diskar som exempel. Ersätt `/dev/sda` och `/dev/sdb` med de diskar du vill använda.

   ```bash
   sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb
   ```

   - För RAID 0: `--level=0` (striping)
   - För RAID 5: `--level=5`

3. **Verifiera RAID-konfigurationen:**

   Efter att RAID-konfigurationen är skapad, kontrollera statusen för RAID-enheten:

   ```bash
   cat /proc/mdstat
   ```

4. **Skapa filsystem på RAID-enheten:**

   När RAID-enheten är skapad, skapa ett filsystem (t.ex. ext4) på den:

   ```bash
   sudo mkfs.ext4 /dev/md0
   ```

5. **Montera RAID-enheten:**

   Skapa en monteringspunkt och montera RAID-enheten:

   ```bash
   sudo mkdir /mnt/raid
   sudo mount /dev/md0 /mnt/raid
   ```

6. **Lägg till RAID i `/etc/fstab` för automatisk montering vid omstart:**

   Få UUID för RAID-enheten:

   ```bash
   sudo blkid /dev/md0
   ```

   Lägg till följande rad i `/etc/fstab`:

   ```bash
   UUID=xxx-xxx-xxx /mnt/raid ext4 defaults 0 2
   ```

### **Steg 2: Skapa NFS-delningar på varje Pi**

Nu ska vi konfigurera NFS så att varje Pi kan dela sin RAID-volym.

1. **Installera NFS-server på varje Pi:**

   ```bash
   sudo apt install nfs-kernel-server
   ```

2. **Konfigurera NFS-delning:**

   Redigera `/etc/exports` för att exportera RAID-volymen via NFS:

   ```bash
   sudo nano /etc/exports
   ```

   Lägg till följande rad för att exportera din RAID-volym:

   ```bash
   /mnt/raid *(rw,sync,no_subtree_check)
   ```

   - `rw` innebär att delningen är skrivbar
   - `sync` innebär att data skrivs till disk innan en operation anses vara klar

3. **Starta om NFS-servern:**

   ```bash
   sudo systemctl restart nfs-kernel-server
   ```

4. **Kontrollera att NFS-delningen fungerar:**

   På en annan Pi eller dator, kontrollera att delningen är tillgänglig:

   ```bash
   showmount -e [Pi-IP]
   ```

### **Steg 3: Montera NFS-delningar på alla enheter**

Nu ska du montera NFS-delningarna på alla enheter (Pi-enheter).

1. **Skapa monteringspunkter på varje Pi:**

   På varje Pi, skapa en monteringspunkt för de andra enheterna. Exempel:

   ```bash
   sudo mkdir /mnt/nfs1
   sudo mkdir /mnt/nfs2
   ```

2. **Montera NFS-delningar:**

   Montera NFS-delningarna från de andra Pi-enheterna till de skapade monteringspunkterna. Exempelvis, om du vill montera Pi1:s delning på Pi2:

   ```bash
   sudo mount [Pi1-IP]:/mnt/raid /mnt/nfs1
   ```

3. **Lägg till NFS-montering i `/etc/fstab` för automatisk montering vid omstart:**

   Lägg till följande rad i `/etc/fstab`:

   ```bash
   [Pi1-IP]:/mnt/raid /mnt/nfs1 nfs defaults 0 0
   ```

### **Steg 4: Installera och konfigurera MergerFS på masterenheten**

Nu ska vi använda **MergerFS** för att kombinera NFS-monteringar från alla Pi-enheter och skapa ett namespace.

1. **Installera MergerFS:**

   På **masterenheten** (den Pi-enhet som kommer att hantera namespace), installera MergerFS:

   ```bash
   sudo apt install mergerfs
   ```

2. **Skapa monteringspunkter för alla NFS-delningar på masterenheten:**

   På masterenheten, skapa monteringspunkter för varje Pi:s NFS-delning:

   ```bash
   sudo mkdir /mnt/nfs1
   sudo mkdir /mnt/nfs2
   sudo mkdir /mnt/nfs3
   ```

3. **Montera NFS-delningar från de andra Pi-enheterna:**

   På masterenheten, montera NFS-delningarna från varje Pi:

   ```bash
   sudo mount [Pi1-IP]:/mnt/raid /mnt/nfs1
   sudo mount [Pi2-IP]:/mnt/raid /mnt/nfs2
   sudo mount [Pi3-IP]:/mnt/raid /mnt/nfs3
   ```

4. **Skapa ett MergerFS namespace:**

   Nu ska vi skapa namespace och använda MergerFS för att kombinera NFS-delningarna. Skapa en mapp för namespace:

   ```bash
   sudo mkdir /mnt/namespace
   ```

   Använd MergerFS för att kombinera de tre NFS-delningarna till ett namespace:

   ```bash
   sudo mergerfs /mnt/nfs1:/mnt/nfs2:/mnt/nfs3 /mnt/namespace
   ```

   MergerFS kommer nu att presentera en sammanslagen vy av dessa tre enheter på `/mnt/namespace`.

5. **Lägg till MergerFS-montering i `/etc/fstab` för automatisk montering vid omstart:**

   Lägg till följande rad i `/etc/fstab` på masterenheten för att montera MergerFS automatiskt vid omstart:

   ```bash
   mergerfs#/mnt/nfs1:/mnt/nfs2:/mnt/nfs3 /mnt/namespace fuse.defaults,allow_other 0 0
   ```

### **Steg 5: Lastbalansering med MergerFS**

För att säkerställa att lagringen balanseras jämt över alla enheter kan vi konfigurera MergerFS för att använda en lastbalanseringsstrategi. Lägg till parameterinställningar när du monterar MergerFS.

Exempel på att använda en fördelning baserad på **fill up**:

```bash
sudo mergerfs -o defaults,allow_other,category.create=ff /mnt/nfs1:/mnt/nfs2:/mnt/nfs3 /mnt/namespace
```

- **category.create=ff**: Skapar filer på den enhet som har mest ledigt utrymme.

MergerFS erbjuder olika strategier för hur filer ska placeras, och genom att justera inställningarna kan du säkerställa att lagringen fördelas jämt.

---

### **Sammanfattning:**
1. **Skapa RAID** på varje Pi-enhet.
2. **Installera och konfigurera NFS** på varje Pi för att dela RAID-enheterna.
3. **Montera NFS-delningar** på alla enheter.
4. **Installera MergerFS** på masterenheten för att skapa ett namespace.
5. **Konfigurera lastbalansering** med MergerFS för att fördela filer över alla enheter.

Nu har du ett system där lagringen fördelas mellan flera Pi-enheter och filerna lagras jämt över dessa enheter genom lastbalansering.
