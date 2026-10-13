# Windows 11 Single-GPU Passthrough (ArcGIS Pro)

This document covers how to set up, operate, and troubleshoot the Windows 11 virtual machine on the `x99` workstation with dedicated passthrough of the NVIDIA GeForce GTX 960 (GM206).

The VM is optimized for high-performance GIS workloads in **ArcGIS Pro** with native GPU acceleration, 1:1 CPU pinning on the Intel Xeon E5-2676 v3, emulated TPM 2.0 (`swtpm`), and UEFI/OVMF.

---

## Storage Layout & ISO Placement

All VM assets, disk images, ISOs, and firmware files reside strictly under `/mnt/kootion512/winnt`:

```
/mnt/kootion512/winnt/
├── isos/
│   ├── win11.iso          <-- Windows 11 official installer ISO
│   └── virtio-win.iso     <-- Red Hat / Fedora VirtIO Windows drivers ISO
├── win11.raw              <-- Primary virtual disk (RAW format, 120GB+)
├── vbios.rom              <-- Clean NVIDIA GTX 960 VBIOS dump
├── win11_VARS.fd          <-- UEFI NVRAM variables (managed by Libvirt)
├── win11-template.xml     <-- Libvirt domain definition template
└── rescue-host.sh         <-- Emergency script to restore host display via SSH
```

### Where to Place the ISOs

The Libvirt template expects two ISO images inside `/mnt/kootion512/winnt/isos/`:

1. **Windows 11 Installer ISO**:
   - Path: `/mnt/kootion512/winnt/isos/win11.iso`
   - Download directly from Microsoft: [Download Windows 11](https://www.microsoft.com/software-download/windows11) (Select "Windows 11 multi-edition ISO").
   - Move or rename the downloaded file to `/mnt/kootion512/winnt/isos/win11.iso`.

2. **VirtIO Windows Drivers ISO**:
   - Path: `/mnt/kootion512/winnt/isos/virtio-win.iso`
   - Since `virtio-win` is part of nixpkgs, you can copy the official ISO directly from the Nix store cache:
     ```bash
     cp $(nix-build '<nixpkgs>' -A virtio-win.src --no-out-link) /mnt/kootion512/winnt/isos/virtio-win.iso
     ```
   - Alternatively, download it from Fedora:
     ```bash
     curl -Lo /mnt/kootion512/winnt/isos/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
     ```

---

## Initial Setup & Preparation

Follow these steps once before launching the virtual machine:

### 1. Enable System Configuration & Reboot

Rebuild the system to activate IOMMU (`intel_iommu=on`, `iommu=pt`) and deploy the Libvirt hooks:

```bash
cd ~/.nix-config
sudo nixos-rebuild boot --flake .#x99
sudo reboot
```

After rebooting, verify that IOMMU groups are active:

```bash
dmesg | grep -i -E "dmar|iommu"
```

### 2. Extract or Download Clean VBIOS

Because this is a Single-GPU setup, the motherboard BIOS corrupts or shadows the GPU ROM during boot. An uncorrupted VBIOS image is required at `/mnt/kootion512/winnt/vbios.rom`:

- **Option A (Recommended)**: Download the matching VBIOS for the GTX 960 (Subsystem `10de:116f`) from the [TechPowerUp Video BIOS Collection](https://www.techpowerup.com/vgabios/). Save it as `/mnt/kootion512/winnt/vbios.rom`.
- **Option B (Local Dump)**:
  ```bash
  sudo sh -c 'echo 1 > /sys/bus/pci/devices/0000:03:00.0/rom'
  sudo sh -c 'cat /sys/bus/pci/devices/0000:03:00.0/rom > /mnt/kootion512/winnt/vbios.rom'
  sudo sh -c 'echo 0 > /sys/bus/pci/devices/0000:03:00.0/rom'
  ```

### 3. Create the Virtual Disk Image

Create a RAW image for maximum I/O throughput (ArcGIS Pro benefits significantly from raw direct I/O compared to qcow2):

```bash
qemu-img create -f raw /mnt/kootion512/winnt/win11.raw 120G
```

### 4. Define the Virtual Machine in Libvirt

Register the domain template with `virsh`:

```bash
virsh define /mnt/kootion512/winnt/win11-template.xml
```

---

## Running and Managing the VM

### Important Safety Rule: Keep SSH Open
> **Warning**: Because this is a **Single GPU Passthrough** setup, starting the VM will detach the GPU from NixOS, stopping the display manager (`ly`) and turning the host screen black until the VM outputs video.
>
> Always maintain an active SSH session from another device (laptop, phone via Tailscale, or another machine on the LAN):
> ```bash
> ssh user@x99
> ```

### Starting the VM

```bash
virsh start win11
```

When this command runs:
1. The Libvirt `prepare` hook executes automatically.
2. `display-manager.service` stops and releases the X11 session.
3. Consoles (`vtcon`) and kernel framebuffers unbind.
4. NVIDIA kernel modules (`nvidia_drm`, `nvidia_modeset`, `nvidia_uvm`, `nvidia`) and HDMI audio unbind.
5. `vfio-pci` claims `0000:03:00.0` and `0000:03:00.1`.
6. QEMU launches and takes control of the physical monitor output.

### Stopping the VM

- **Graceful Shutdown**: Shut down Windows normally from the Start Menu (`Start -> Power -> Shut down`).
- **Command Line**:
  ```bash
  virsh shutdown win11
  ```
- **Force Off** (if Windows freezes):
  ```bash
  virsh destroy win11
  ```

Once QEMU terminates, the `release` hook runs automatically:
1. Devices detach from `vfio-pci` and reattach to the host.
2. NVIDIA modules reload in proper dependency order.
3. Consoles and framebuffers rebind.
4. `display-manager.service` restarts, presenting the `ly` login screen.

---

## Windows 11 Installation Walkthrough

1. **Booting the Installer**:
   - Start the VM: `virsh start win11`.
   - Press any key when prompted to boot from the Windows 11 CD/DVD.
2. **Loading the VirtIO Storage Driver**:
   - When the installer reaches "Where do you want to install Windows?", the list will be empty because the VirtIO disk controller requires a driver.
   - Click **Load driver** -> **Browse**.
   - Navigate to the VirtIO CD drive -> `viostor` -> `w11` -> `amd64`.
   - Select the Red Hat VirtIO SCSI controller driver. The 120GB RAW disk will now appear.
   - Proceed with standard Windows installation.
3. **Installing Network and Guest Drivers**:
   - Once at the Windows desktop, open the VirtIO CD drive in File Explorer.
   - Run `virtio-win-gt-x64.msi` (or `virtio-win-guest-tools.exe`) to install Ethernet (`NetKVM`), Ballooning, and QEMU Guest Agent.
4. **Installing NVIDIA Graphics Drivers**:
   - Download and install the latest NVIDIA GeForce Game Ready / Studio driver for GTX 960 from [nvidia.com](https://www.nvidia.com/Download/index.aspx).
   - Once installed, open Task Manager -> Performance -> GPU to verify full DirectX 12, Vulkan, and hardware acceleration.

---

## Configuring ArcGIS Pro

1. Install ArcGIS Pro on Windows 11.
2. Open ArcGIS Pro -> **Settings** -> **Options** -> **Display**:
   - **Rendering engine**: Select **DirectX** (or **OpenGL** depending on your dataset requirements).
   - **Antialiasing**: Set to *High* or *Normal*.
   - Check **Enable hardware antialiasing**.
3. Verify 3D Scene / Local Scene rendering:
   - Basemaps, elevation surfaces, and raster layers will render natively via the GTX 960 with zero software emulation overhead.

---

## Troubleshooting & Emergency Recovery

### Monitor Stays Black & VM Does Not Boot

If a hook fails or the VM encounters an error, connect via SSH and execute the emergency restore script:

```bash
sudo /mnt/kootion512/winnt/rescue-host.sh
```

This immediately terminates any stuck QEMU processes, rebinds the GPU back to `nvidia` and `snd_hda_intel`, re-enables `vtcon`, and restarts `display-manager.service`.

### Checking Logs

To diagnose transition failures or kernel errors:

```bash
# Custom Libvirt hook execution log (detailed step-by-step progress)
cat /var/log/libvirt/custom_hooks.log

# Libvirt daemon journal
journalctl -u libvirtd -f

# QEMU domain log
cat /var/log/libvirt/qemu/win11.log

# Kernel hardware messages
dmesg | grep -i -E "vfio|nvidia|iommu"
```

### NVIDIA Code 43 in Windows Device Manager

If Windows Device Manager shows a yellow triangle with Code 43 on the GTX 960:
1. Ensure the VBIOS file exists at `/mnt/kootion512/winnt/vbios.rom` and matches the subsystem ID `10de:116f`.
2. Confirm the XML includes `<kvm><hidden state='on'/></kvm>` and the Hyper-V vendor ID spoofing.
3. Verify that the HDMI audio device `0000:03:00.1` is passed through alongside the video device `0000:03:00.0`.
