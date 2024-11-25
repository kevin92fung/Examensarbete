# Define VM Name
$VMName = "MyVM"

# Define the parent path where the VM directory will be created
$ParentPath = "C:\VM"

# Define the full VM path (VM directory and subdirectories)
$VMPath = "$ParentPath\$VMName"
$VMDirPath = "$VMPath\Virtual Machines"
$VHDDirPath = "$VMPath\Virtual Hard Disks"

# Define the path to the placeholder VHDX file
$VHDXPath = "C:\VM\Files\Backup\UbuntuServer.vhdx"

# Define the target path for the copied VHDX
$VHDXTargetPath = "$VHDDirPath\$VMName.vhdx"

# Define the paths for the 6 new VHDX disks
$VHDXPaths = @()
for ($i = 1; $i -le 6; $i++) {
    $VHDXPaths += "$VHDDirPath\$VMName-Disk$i.vhdx"
}

# Create the main VM directory and subdirectories
New-Item -Path $VMPath -ItemType Directory -Force
New-Item -Path $VMDirPath -ItemType Directory -Force
New-Item -Path $VHDDirPath -ItemType Directory -Force

# Copy the VHDX file to the virtual hard disks directory
Copy-Item -Path $VHDXPath -Destination $VHDXTargetPath

# Create the VM with Generation 2, 4GB RAM, Secure Boot off, Checkpoints off, Default Switch
New-VM -Name $VMName -Generation 2 -MemoryStartupBytes 4GB -Path $VMPath -VHDPath $VHDXTargetPath -SwitchName "Default Switch"

# Disable Checkpoints (Snapshots)
Set-VM -Name $VMName -CheckpointType Disabled

# Set Secure Boot to Off (if not already)
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

# Create and attach 6 additional VHDX disks, each 10 GB dynamically expanding
foreach ($VHDXPath in $VHDXPaths) {
    # Create the VHDX with dynamic expansion
    New-VHD -Path $VHDXPath -SizeBytes 10GB -Dynamic

    # Attach the VHDX to the VM
    Add-VMHardDiskDrive -VMName $VMName -Path $VHDXPath
}

# Start the VM
Start-VM -Name $VMName
Write-Host "VM $VMName created successfully with 4GB RAM, Secure Boot Off, Checkpoints Disabled, and all VHDX disks attached."