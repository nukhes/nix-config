# Windows 11 Single-GPU Passthrough (ArcGIS Pro)

This document covers how to set up, operate, and troubleshoot the Windows 11 virtual machine on the `x99` workstation with dedicated passthrough of the NVIDIA GeForce GTX 960 (GM206).

The VM is optimized for high-performance GIS workloads in **ArcGIS Pro** with native GPU acceleration, 1:1 CPU pinning on the Intel Xeon E5-2676 v3, emulated TPM 2.0 (`swtpm`), native emulated NVMe, USB input passthrough, and UEFI/OVMF.

---

## Storage Layout & Asset Placement

All VM assets, disk images, ISOs, and firmware files reside under the canonical path `/var/lib/win11`, which is declaratively linked by NixOS (`systemd.tmpfiles.rules`) to the physical storage path configured in [`modules/nixos/x99-vfio.nix`](file:///home/user/.nix-config/modules/nixos/x99-vfio.nix) (`modules.x99.vfio.storageDir`):

```text
/var/lib/win11/ (-> symlink to physical storage configured in NixOS)
├── isos/
│   ├── win11.iso          <-- Windows 11 installer ISO (unattended EFI boot)
│   └── virtio-win.iso     <-- Red Hat / Fedora VirtIO Windows drivers ISO
├── win11.raw              <-- Primary virtual disk (RAW format, 120GB+, emulated NVMe)
├── vbios.rom              <-- Clean NVIDIA GTX 960 VBIOS dump
├── win11_VARS.fd          <-- UEFI NVRAM variables (managed by Libvirt)
├── win11-template.xml     <-- Libvirt domain definition template
├── win11-start.sh         <-- Idempotent VM starter
├── win11-stop.sh          <-- Graceful/forceful VM stopper (ACPI + timeout fallback)
├── win11-status.sh        <-- Diagnostic script reporting VM state, block, & USB
├── win11-restart.sh       <-- VM restart helper
└── rescue-host.sh         <-- Emergency script to restore host display via SSH
```

A version-controlled copy of the Libvirt definition template is maintained in this repository at [`docs/win11-template.xml`](file:///home/user/.nix-config/docs/win11-template.xml).

### Where to Place the ISOs & VBIOS

The Libvirt template expects two ISO images and the clean VBIOS inside `/var/lib/win11`:

1. **Automatic Extraction via `x99-vfio-dump`**:
   The NixOS configuration equips the system with `x99-vfio-dump`. Run:
   ```bash
   x99-vfio-dump
   ```
   This automatically copies the official `virtio-win.iso` directly from the Nix store cache to `/var/lib/win11/isos/virtio-win.iso` and dumps an uncorrupted copy of the GTX 960 VBIOS to `/var/lib/win11/vbios.rom`.

2. **Windows 11 Installer ISO**:
   - Path: `/var/lib/win11/isos/win11.iso`
   - Download directly from Microsoft or use your desired Windows 11 installation media.
   - **Important UEFI Boot Note**: To prevent the 4-second `"Press any key to boot from CD or DVD"` timeout in OVMF (which drops to `No bootable option found` before GPU displays sync), ensure the ISO boots via `efisys_noprompt.bin` / `cdboot_noprompt.efi`.

---

## Initial Setup & Preparation

Follow these steps once before launching the virtual machine:

### 1. Enable System Configuration & Reboot

Rebuild the system to activate IOMMU (`intel_iommu=on`, `iommu=pt`), deploy the Libvirt hooks, and install the helper commands:

```bash
cd ~/.nix-config
sudo nixos-rebuild boot --flake .#x99
sudo reboot
```

After rebooting, verify that IOMMU groups are active:

```bash
dmesg | grep -i -E "dmar|iommu"
```

### 2. Create the Virtual Disk Image

Create a RAW image for maximum I/O throughput:

```bash
qemu-img create -f raw /var/lib/win11/win11.raw 120G
```

### 3. Define the Virtual Machine in Libvirt

Register the domain template with `virsh` in the system instance:

```bash
virsh -c qemu:///system define /var/lib/win11/win11-template.xml
```

---

## Running and Managing the VM

### Important Safety Rule: Keep SSH Open
> [!WARNING]
> Because this is a **Single GPU Passthrough** setup, starting the VM detaches the GTX 960 from NixOS, stopping the display manager (`ly`) and taking over the physical monitor until the VM stops.
>
> Always maintain an active SSH session from another device (laptop, phone via Tailscale, or LAN):
> ```bash
> ssh user@x99
> ```

### Idiomatic VM Commands & Aliases

NixOS provides dedicated, idempotent CLI commands and aliases on `x99`:

| Action | Primary Command | Short Aliases | Behavior |
| :--- | :--- | :--- | :--- |
| **Start VM** | `win11-start` | `win-start`, `vm-start` | Idempotent: checks state, auto-defines from template if missing, starts virtual network, and claims GPU. No-op if already running. |
| **Stop VM** | `win11-stop` | `win-stop`, `vm-stop` | Idempotent: initiates ACPI shutdown, waits up to 25s for clean guest shutdown, then auto-forces `destroy` if unresponsive. No-op if already shut off. |
| **Force Stop** | `win11-stop -f` | `win-stop -f`, `vm-stop -f` | Immediately issues `virsh destroy win11` and triggers the host release hook. |
| **Restart VM** | `win11-restart` | `win-restart`, `vm-restart` | Cleanly stops the VM, allows the host/VFIO transition to settle, and starts it again. |
| **Check Status** | `win11-status` | `win-status`, `vm-status` | Displays domain state, CPU/RAM usage, attached USB devices, and virtual disks. |
| **Emergency Host Rescue** | `sudo x99-vfio-rescue` | — | Kills hung QEMU instances, rebinds PCI devices to `nvidia` & `snd_hda_intel`, re-enables `vtcon`, and restarts `display-manager.service`. |

*(The helper shell scripts are also executable directly at `/var/lib/win11/win11-*.sh` even prior to system rebuilds).*

---

## Hardware Passthrough Architecture

### 1. Dedicated GPU Passthrough (NVIDIA GTX 960)
- **PCI Video**: `0000:03:00.0` passed through to PCIe root port `0x01` (`multifunction=on`).
- **PCI Audio**: `0000:03:00.1` passed through to `0x01.0x1`.
- **VBIOS**: Clean ROM loaded via `<rom file='/var/lib/win11/vbios.rom'/>` to bypass UEFI shadowing corruption.
- **Hyper-V & KVM Spoofing**: Configured with `<kvm><hidden state='on'/></kvm>` and Hyper-V enlightened timers to prevent NVIDIA Error 43.

### 2. USB Input Passthrough (Keyboard & Mouse)
The domain template forwards physical USB devices directly to the guest:
- **Keyboard**: Sino Wealth USB Keyboard (`vendor=0x258a`, `product=0x013b`)
- **Mouse / Wireless Receiver**: Xenta 2.4G Wireless Device (`vendor=0x1d57`, `product=0xfa60`)
- **Safety Policy**: Defined with `startupPolicy='optional'`, ensuring the VM boots successfully even if a peripheral is temporarily unplugged.

To inspect or pass through other USB devices (e.g. gamepads, DACs, flash drives):
```bash
lsusb
```
Locate the `ID <vendor>:<product>` and add them as `<hostdev mode='subsystem' type='usb'>` in the domain XML.

### 3. Native Emulated NVMe Disk
- Configured as `<target dev='nvme0n1' bus='nvme'/>` with `<serial>win11nvme0</serial>`.
- Windows 11 includes native inbox drivers (`stornvme.sys`), eliminating the requirement to load third-party drivers during setup.
- Provides native PCIe multi-queue storage I/O, matching the performance required by ArcGIS Pro.

---

## Windows 11 Installation Walkthrough

1. **Booting the Installer**:
   - Start the VM: `win-start`.
   - The installer boots directly into Windows Setup automatically (using the unattended EFI bootloader `efisys_noprompt.bin`, avoiding OVMF timeout drops).
   - Your physical USB keyboard and mouse on x99 control the VM directly.

2. **Selecting the Target Drive**:
   - The 120GB RAW disk appears immediately in "Where do you want to install Windows?" as **Drive 0 Unallocated Space (120.0 GB)**.
   - **No manual driver loading or browsing is needed** (bypassing WinPE file picker bugs common in custom lightweight ISOs).
   - Select the drive and click **Next** to proceed with installation.

3. **Reboots during Installation**:
   - During setup reboots, QEMU performs a soft reset. The GPU remains attached to the VM, and the display will re-initialize in the guest automatically.

4. **Post-Install: Guest & Network Drivers**:
   - Once at the Windows desktop, open File Explorer and navigate to the VirtIO CD drive (`D:` or `E:`).
   - Run `virtio-win-gt-x64.msi` (or `virtio-win-guest-tools.exe`) to install Ethernet (`NetKVM`), Memory Ballooning, and the QEMU Guest Agent.

5. **Installing NVIDIA Graphics Drivers**:
   - Download and install the latest NVIDIA GeForce Game Ready driver for the GTX 960 from [nvidia.com](https://www.nvidia.com/Download/index.aspx).
   - Open Task Manager -> Performance -> GPU to verify full DirectX 12, Vulkan, and hardware acceleration.

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

### Monitor Stays Black or Host Session Lost

If a hook fails or the VM encounters an error during startup, connect via SSH from your other machine and run:

```bash
sudo x99-vfio-rescue
# or:
sudo /var/lib/win11/rescue-host.sh
```

This immediately kills any frozen QEMU processes, rebinds the PCI devices to `nvidia` and `snd_hda_intel`, re-enables `vtcon`, and restarts `display-manager.service`.

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
1. Ensure the VBIOS file exists at `/var/lib/win11/vbios.rom` and matches subsystem ID `10de:116f`.
2. Confirm the XML includes `<kvm><hidden state='on'/></kvm>` and the Hyper-V vendor ID spoofing.
3. Verify that the HDMI audio device `0000:03:00.1` is passed through alongside the video device `0000:03:00.0`.

### "No bootable option found" / UEFI Boot Menu Loop

If the VM gets stuck at `Press any key to enter boot manager menu: No bootable option found`:
- Windows installer ISOs prompt `Press any key to boot from CD or DVD.....` with a 4-second timeout. If monitor HDMI/DP sync takes a few seconds or input is delayed, OVMF aborts the boot.
- The ISO at `/var/lib/win11/isos/win11.iso` has been patched to point its El Torito EFI boot entry to Microsoft's unattended boot catalog (`efisys_noprompt.bin`), which enters Windows Setup immediately with zero prompt.

### Custom Lightweight ISOs: "Browse" Error & NVMe Bypass

If using a custom stripped Windows image (e.g., FBConan X-Lite, Tiny11):
- Stripped WinPE (`boot.wim`) images often remove `comdlg32.dll` and shell folder picker libraries, causing an error when clicking **Browse** in the "Load driver" window.
- **Bypass**: The virtual disk is attached as native emulated NVMe (`bus='nvme'`). Windows 11 includes built-in `stornvme.sys` drivers, allowing the installer to detect the 120GB disk directly without loading VirtIO storage drivers during setup.
- If ArcGIS Pro later encounters missing OS runtime errors (e.g., .NET Desktop Runtime, Edge WebView2 Evergreen, WMI services), replace the ISO with the official Microsoft Windows 11 multi-edition ISO.
