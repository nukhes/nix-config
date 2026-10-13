_:

{
  nixos.modules.x99 =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # Ferramentas do sistema com caminhos absolutos do Nix Store
      systemctl = "${pkgs.systemd}/bin/systemctl";
      modprobe = "${pkgs.kmod}/bin/modprobe";
      fuser = "${pkgs.psmisc}/bin/fuser";
      virsh = "${pkgs.libvirt}/bin/virsh";
      sleep = "${pkgs.coreutils}/bin/sleep";
      echo = "${pkgs.coreutils}/bin/echo";
      date = "${pkgs.coreutils}/bin/date";
      mkdir = "${pkgs.coreutils}/bin/mkdir";

      # Script de início: Isola a GPU do host NixOS e transfere para o VFIO
      qemuHookPrepare = pkgs.writeShellScript "qemu-hook-prepare-win11" ''
        set -euo pipefail
        LOGFILE="/var/log/libvirt/custom_hooks.log"
        ${mkdir} -p /var/log/libvirt
        exec >> "$LOGFILE" 2>&1

        ${echo} "=== [$(${date})] Iniciando gancho PREPARE (Single GPU Passthrough) ==="

        # 1. Parar o gerenciador de exibição (ly / display-manager)
        ${echo} "Parando display-manager.service..."
        ${systemctl} stop display-manager.service || true
        ${sleep} 2

        # 2. Desvincular consoles virtuais (VTcon)
        ${echo} "Desvinculando consoles virtuais..."
        for vt in /sys/class/vtconsole/vtcon*; do
          if [ -e "$vt/bind" ]; then
            ${echo} 0 > "$vt/bind" 2>/dev/null || true
          fi
        done

        # 3. Desvincular framebuffers do kernel
        ${echo} "Desvinculando framebuffers..."
        if [ -e /sys/bus/platform/drivers/efi-framebuffer/unbind ]; then
          ${echo} efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true
        fi
        if [ -e /sys/bus/platform/drivers/simple-framebuffer/unbind ]; then
          ${echo} simple-framebuffer.0 > /sys/bus/platform/drivers/simple-framebuffer/unbind 2>/dev/null || true
        fi

        # 4. Finalizar processos remanescentes com handles abertos na GPU
        ${echo} "Finalizando processos que utilizam /dev/nvidia* e /dev/dri/*..."
        ${fuser} -k -9 /dev/nvidia* 2>/dev/null || true
        ${fuser} -k -9 /dev/dri/* 2>/dev/null || true
        ${sleep} 1

        # 5. Descarregar módulos do driver NVIDIA (ordem inversa de dependência)
        ${echo} "Descarregando módulos de kernel da NVIDIA..."
        ${modprobe} -r nvidia_drm 2>/dev/null || true
        ${modprobe} -r nvidia_modeset 2>/dev/null || true
        ${modprobe} -r nvidia_uvm 2>/dev/null || true
        ${modprobe} -r nvidia 2>/dev/null || true

        # 6. Desvincular o controlador de áudio HDMI da GPU do driver snd_hda_intel
        ${echo} "Desvinculando áudio HDMI (0000:03:00.1)..."
        if [ -d /sys/bus/pci/drivers/snd_hda_intel/0000:03:00.1 ]; then
          ${echo} 0000:03:00.1 > /sys/bus/pci/drivers/snd_hda_intel/unbind 2>/dev/null || true
        fi

        # 7. Carregar o driver VFIO e anexar os dispositivos da GPU
        ${echo} "Carregando vfio-pci e isolando dispositivos..."
        ${modprobe} vfio-pci
        ${virsh} nodedev-detach pci_0000_03_00_0 2>/dev/null || true
        ${virsh} nodedev-detach pci_0000_03_00_1 2>/dev/null || true

        ${echo} "=== [$(${date})] GPU transferida com sucesso para o VFIO ==="
      '';

      # Script de término: Recupera a GPU do VFIO e restaura o host NixOS
      qemuHookRelease = pkgs.writeShellScript "qemu-hook-release-win11" ''
        set -euo pipefail
        LOGFILE="/var/log/libvirt/custom_hooks.log"
        ${mkdir} -p /var/log/libvirt
        exec >> "$LOGFILE" 2>&1

        ${echo} "=== [$(${date})] Iniciando gancho RELEASE (Restauração do Host) ==="

        # 1. Reanexar os dispositivos PCI ao host através do virsh
        ${echo} "Reanexando dispositivos PCI ao host..."
        ${virsh} nodedev-reattach pci_0000_03_00_0 2>/dev/null || true
        ${virsh} nodedev-reattach pci_0000_03_00_1 2>/dev/null || true

        # 2. Descarregar módulo vfio_pci
        ${echo} "Descarregando vfio_pci..."
        ${modprobe} -r vfio_pci 2>/dev/null || true

        # 3. Recarregar os módulos de kernel da NVIDIA (ordem direta)
        ${echo} "Recarregando módulos de kernel da NVIDIA..."
        ${modprobe} nvidia
        ${modprobe} nvidia_modeset
        ${modprobe} nvidia_uvm
        ${modprobe} nvidia_drm

        # 4. Reanexar o áudio HDMI ao driver snd_hda_intel
        ${echo} "Reanexando áudio HDMI ao snd_hda_intel..."
        if [ -e /sys/bus/pci/drivers/snd_hda_intel/bind ]; then
          ${echo} 0000:03:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
        fi

        # 5. Reativar os consoles virtuais (VTcon)
        ${echo} "Reativando consoles virtuais..."
        for vt in /sys/class/vtconsole/vtcon*; do
          if [ -e "$vt/bind" ]; then
            ${echo} 1 > "$vt/bind" 2>/dev/null || true
          fi
        done

        # 6. Reanexar framebuffers caso suportado
        if [ -e /sys/bus/platform/drivers/efi-framebuffer/bind ]; then
          ${echo} efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind 2>/dev/null || true
        fi

        # 7. Reiniciar o gerenciador de exibição (ly)
        ${echo} "Iniciando display-manager.service..."
        ${systemctl} start display-manager.service || true

        ${echo} "=== [$(${date})] Host restaurado com sucesso ==="
      '';

      dumpVbiosAndVirtioIso = pkgs.writeShellScriptBin "x99-vfio-dump" ''
        set -euo pipefail

        output_dir="/mnt/kootion512/winnt"
        iso_dir="$output_dir/isos"
        rom_path="/sys/bus/pci/devices/0000:03:00.0/rom"
        rom_enabled=0

        cleanup_rom() {
          if [ "$rom_enabled" -eq 1 ]; then
            printf '0\n' | ${pkgs.sudo}/bin/sudo ${pkgs.coreutils}/bin/tee "$rom_path" >/dev/null || true
          fi
        }
        trap cleanup_rom EXIT

        ${pkgs.sudo}/bin/sudo -v
        ${pkgs.coreutils}/bin/mkdir -p "$iso_dir"
        ${pkgs.coreutils}/bin/cp ${pkgs.virtio-win.src} "$iso_dir/virtio-win.iso"
        printf 'ISO do VirtIO copiada para %s\n' "$iso_dir/virtio-win.iso"

        printf '1\n' | ${pkgs.sudo}/bin/sudo ${pkgs.coreutils}/bin/tee "$rom_path" >/dev/null
        rom_enabled=1
        ${pkgs.sudo}/bin/sudo ${pkgs.coreutils}/bin/cat "$rom_path" > "$output_dir/vbios.rom"
        printf 'VBIOS salvo em %s/vbios.rom\n' "$output_dir"

        cleanup_rom
        rom_enabled=0
        trap - EXIT
      '';

      # Dispatcher mestre do Libvirt (/var/lib/libvirt/hooks/qemu)
      qemuHookDispatcher = pkgs.writeShellScript "libvirt-qemu-hook" ''
        GUEST_NAME="''${1:-}"
        OPERATION="''${2:-}"
        SUB_OPERATION="''${3:-}"

        if [ "$GUEST_NAME" = "win11" ]; then
          if [ "$OPERATION" = "prepare" ] && [ "$SUB_OPERATION" = "begin" ]; then
            ${qemuHookPrepare}
          elif [ "$OPERATION" = "release" ] && [ "$SUB_OPERATION" = "end" ]; then
            ${qemuHookRelease}
          fi
        fi
      '';
    in
    {
      # 1. Parâmetros de Kernel para IOMMU
      boot.kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
      ];

      # 2. Carregamento dos módulos VFIO no kernel
      boot.kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];

      # 3. Configuração do Libvirt e QEMU para executar como root
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

      # 4. Estrutura de Diretórios da VM e Injeção Declarativa do Hook
      systemd.tmpfiles.rules = [
        # Diretório dedicado da VM no SSD Kootion 512
        "d /mnt/kootion512/winnt 0775 user users - -"
        "d /mnt/kootion512/winnt/isos 0775 user users - -"
        # Hook mestre do Libvirt
        "d /var/lib/libvirt/hooks 0755 root root - -"
        "L+ /var/lib/libvirt/hooks/qemu 0755 root root - ${qemuHookDispatcher}"
      ];

      # 5. Pacotes essenciais para virtualização com GPU Passthrough e Windows 11
      environment.systemPackages = with pkgs; [
        virt-manager
        virtio-win
        swtpm
        pciutils
        usbutils
        libguestfs
        dumpVbiosAndVirtioIso
      ];
    };
}
