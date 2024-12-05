### Guide: Installera WSL, Kubernetes och ansluta till ett kluster

Den här guiden visar steg för steg hur du installerar **WSL**, installerar **kubectl**, och ansluter till ett Kubernetes-kluster från din Windows-dator.

---

## Steg 1: Installera WSL

1. **Aktivera WSL och nödvändiga komponenter:**
   - Öppna PowerShell som administratör och kör följande:
     ```powershell
     wsl --install
     ```
   - Detta installerar både WSL2 och en standarddistribution (vanligtvis Ubuntu).

2. **Kontrollera installationen:**
   - Efter installationen, verifiera att WSL körs:
     ```powershell
     wsl --list --verbose
     ```
   - Du bör se en lista med tillgängliga distributioner och deras tillstånd. Exempel:
     ```
       NAME      STATE           VERSION
     * Ubuntu    Running         2
     ```

3. **Starta WSL och ställ in din användare:**
   - Kör:
     ```powershell
     wsl
     ```
   - Följ instruktionerna för att skapa ett användarkonto och lösenord.

---

## Steg 2: Installera `kubectl` i WSL

1. **Uppdatera paketlistor och installera nödvändiga verktyg:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y curl apt-transport-https
   ```

2. **Hämta och installera `kubectl`:**
   - Kör följande kommandon för att installera den senaste versionen:
     ```bash
     curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
     chmod +x kubectl
     sudo mv kubectl /usr/local/bin/
     ```

3. **Verifiera installationen:**
   - Kontrollera att `kubectl` fungerar:
     ```bash
     kubectl version --client
     ```

---

## Steg 3: Koppla `kubectl` till Kubernetes-klustret

1. **Hämta `k3s.yaml` från din master-nod:**
   - Anslut till din master-nod via SSH:
     ```bash
     ssh user@<master-node-ip>
     ```
   - Kopiera Kubernetes-konfigurationsfilen (`k3s.yaml`) till din lokala dator:
     ```bash
     scp user@<master-node-ip>:/etc/rancher/k3s/k3s.yaml ~/k3s.yaml
     ```

2. **Flytta konfigurationsfilen till rätt plats:**
   - Öppna WSL och kör följande:
     ```bash
     mkdir -p ~/.kube
     mv ~/k3s.yaml ~/.kube/config
     ```

3. **Uppdatera kluster-URL i konfigurationsfilen:**
   - Redigera filen:
     ```bash
     nano ~/.kube/config
     ```
   - Ändra värdet för `server:` till IP-adressen för din master-nod eller en virtuell IP-adress för hög tillgänglighet:
     ```yaml
     server: https://<master-node-ip>:6443
     ```

4. **Testa anslutningen:**
   - Verifiera att `kubectl` kan prata med klustret:
     ```bash
     kubectl get nodes
     ```

---

## Steg 4: (Valfritt) Sätt `KUBECONFIG` som standard

Om du vill undvika att ange filens plats manuellt varje gång, gör följande:

1. **Lägg till variabeln i `~/.bashrc`:**
   ```bash
   echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
   source ~/.bashrc
   ```

---

### Klar!
Nu har du en fungerande WSL-instans med `kubectl` som kan användas för att hantera ditt Kubernetes-kluster.