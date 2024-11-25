## **1. Förberedelser**
1. **Ladda ner Debian ISO**:  
   Besök [Debians officiella hemsida](https://www.debian.org/distrib/) och ladda ner den senaste versionen av Debian.

2. **Skapa ett bootbart USB-minne**:  
   Använd verktyg som [Rufus](https://rufus.ie/) (för Windows) eller `dd` (för Linux). Exempel med `dd`:
   ```bash
   sudo dd if=/path/to/debian.iso of=/dev/sdX bs=4M status=progress
   ```
   Byt ut `/dev/sdX` mot rätt enhet.

3. Starta datorn från USB-minnet och välj **Install** eller **Graphical Install**.

[⬆️ Till toppen](#top)

---

## **2. Installera Debian**
### **Steg 1: Välj språk och tangentbord**
- Välj språk, region och tangentbordslayout som passar dig.

### **Steg 2: Konfigurera nätverk**
- Ange ett värdnamn för din maskin (t.ex. `debian-server`).
- Om du inte har en DHCP-server kan du konfigurera nätverket manuellt.

### **Steg 3: Ange lösenord och skapa användare**
1. Ställ in ett lösenord för **root**.  
   (Du kan lämna detta tomt om du enbart vill använda en sudo-användare.)
2. Skapa en ny användare genom att ange:
   - Fullständigt namn.
   - Användarnamn (t.ex. `kevin`).
   - Lösenord.

### **Steg 4: Partitionera disken**
- Välj **Guided - use entire disk**.
- Välj standardalternativet **All files in one partition** (om du inte har speciella behov).

### **Steg 5: Software Selection**
1. När du når **Software Selection**:
   - Avmarkera allt utom:
     - **Standard System Utilities**
     - **SSH Server**
2. Fortsätt till nästa steg.

### **Steg 6: Installera GRUB**
- Välj att installera GRUB bootloader och välj rätt disk.

### **Steg 7: Slutför installationen**
- Starta om systemet när installationen är klar och ta bort installationsmediet.

[⬆️ Till toppen](#top)

---

## **3. Efter installationen**
### **Steg 1: Logga in**
- Logga in med den användare och lösenord du skapade under installationen.

### **Steg 2: Installera `sudo`**
1. Uppdatera paketlistan:
   ```bash
   su -
   apt update
   apt install sudo
   ```

2. Logga ut från root:
   ```bash
   exit
   ```

### **Steg 3: Lägg till användare i sudo-gruppen**
1. Lägg till din användare i gruppen `sudo`:
   ```bash
   su -
   usermod -aG sudo användarnamn
   exit
   ```
   Byt ut `användarnamn` mot det användarnamn du valde under installationen.

2. Bekräfta att användaren är en sudoer:
   ```bash
   groups användarnamn
   ```
   Du bör se `sudo` som en av grupperna.

3. Logga ut och logga in igen för att tillämpa ändringarna.

[⬆️ Till toppen](#top)

---

## **4. Testa sudo**
1. Kör ett kommando som kräver sudo-behörighet:
   ```bash
   sudo apt update
   ```
2. Ange lösenordet för din användare.
3. Om kommandot körs utan problem är allt korrekt inställt.

[⬆️ Till toppen](#top)

---

## **5. Valfria inställningar**
### **Ge lösenordsfri sudo-åtkomst**
1. Öppna `sudoers`-filen:
   ```bash
   sudo visudo
   ```

2. Lägg till följande rad längst ner:
   ```bash
   användarnamn ALL=(ALL:ALL) NOPASSWD: ALL
   ```

3. Spara och stäng (`Ctrl + O`, sedan `Ctrl + X`).

[⬆️ Till toppen](#top)

---

## **Felsökning**
### Om användaren inte kan använda sudo:
1. Kontrollera att användaren är i gruppen `sudo`:
   ```bash
   groups användarnamn
   ```

2. Kontrollera att `sudo` är installerat:
   ```bash
   sudo --version
   ```

3. Om problemet kvarstår, redigera `sudoers`-filen manuellt:
   ```bash
   su -
   visudo
   ```
   Lägg till:
   ```bash
   användarnamn ALL=(ALL:ALL) ALL
   ```




---
---
---




# Steg för att lägga till 6 nya VHDX-diskar till Debian VM i Hyper-V

---

## **1. Skapa och bifoga 6 nya VHDX-diskar**

### **1.1. Skapa VHDX-diskarna med PowerShell**

Kör följande PowerShell-skript för att skapa och bifoga 6 nya VHDX-diskar med dynamisk expansion till din VM. Byt ut sökvägen och VM-namnet om det behövs.

```powershell
# Definiera VM-namn och VHDX-sökväg
$VMName = "Debian"
$VHDDirPath = "C:\VM\Debian\Virtual Hard Disks"

# Skapa och bifoga 6 nya VHDX-diskar med dynamisk expansion
for ($i = 1; $i -le 6; $i++) {
    $VHDXPath = "$VHDDirPath\$VMName-Disk$i.vhdx"
    
    # Skapa VHDX med dynamisk expansion
    New-VHD -Path $VHDXPath -SizeBytes 10GB -Dynamic

    # Bifoga den nyskapade VHDX-disk till VM:n
    Add-VMHardDiskDrive -VMName $VMName -Path $VHDXPath
}
```
