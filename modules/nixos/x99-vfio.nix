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
      cfg = config.modules.x99.vfio;

      # Caminho físico configurado (ponto único de definição no repositório)
      # e caminho canônico estável exposto ao Libvirt e à documentação.
      vmStorageDir = cfg.storageDir;
      vmCanonicalDir = "/var/lib/win11";

      # Template XML da VM fornecido pelo repositório
      win11Template = ../../docs/win11-template.xml;

      # ─────────────────────────────────────────────────────────────────
      # VETOR CPUID 0x40000000: assinatura KVMKVMKVM
      # O XML com <kvm><hidden/></kvm> suprime o bit hypervisor do leaf 0x1,
      # mas NÃO o vendor string do leaf 0x40000000. Sem este patch, Anti-Cheats
      # Ring-0 leem "KVMKVMKVM" e confirmam virtualização.
      # --replace-fail aborta o build se a string mudar numa versão futura.
      # ─────────────────────────────────────────────────────────────────
      qemuGhosted = pkgs.qemu_kvm.overrideAttrs (prevAttrs: {
        pname = "qemu-ghosted";
        postPatch = (prevAttrs.postPatch or "") + ''
          substituteInPlace target/i386/kvm/kvm.c \
            --replace-fail 'memcpy(signature, "KVMKVMKVM\0\0\0", 12);' \
                           'memcpy(signature, "GenuineIntel", 12);'
        '';
      });

      # Ferramentas do sistema com caminhos absolutos do Nix Store
      systemctl = "${pkgs.systemd}/bin/systemctl";
      modprobe = "${pkgs.kmod}/bin/modprobe";
      fuser = "${pkgs.psmisc}/bin/fuser";
      virsh = "${pkgs.libvirt}/bin/virsh";
      sleep = "${pkgs.coreutils}/bin/sleep";
      echo = "${pkgs.coreutils}/bin/echo";
      date = "${pkgs.coreutils}/bin/date";
      mkdir = "${pkgs.coreutils}/bin/mkdir";
      grep = "${pkgs.gnugrep}/bin/grep";
      pkill = "${pkgs.procps}/bin/pkill";
      sudo = "/run/wrappers/bin/sudo";

      # Script de início: Isola a GPU do host NixOS e transfere para o VFIO
      qemuHookPrepare = pkgs.writeShellScript "qemu-hook-prepare-win11" ''
        set -euo pipefail
        LOGFILE="/var/log/libvirt/custom_hooks.log"
        ${mkdir} -p /var/log/libvirt
        exec >> "$LOGFILE" 2>&1

        ${echo} "=== [$(${date})] Iniciando gancho PREPARE (Single GPU Passthrough) ==="

        # 0. Verificações pré-voo (pre-flight checks) para não derrubar a sessão em vão
        if [ ! -d /sys/kernel/iommu_groups ] || [ -z "$(${pkgs.coreutils}/bin/ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
          ${echo} "ERRO CRÍTICO: IOMMU não está ativo no host. Abortando PREPARE para proteger a sessão gráfica." >&2
          exit 1
        fi

        if [ ! -f "${vmCanonicalDir}/win11.raw" ]; then
          ${echo} "ERRO CRÍTICO: Disco ${vmCanonicalDir}/win11.raw não encontrado. Abortando PREPARE." >&2
          exit 1
        fi

        if [ ! -f "${vmCanonicalDir}/vbios.rom" ]; then
          ${echo} "ERRO CRÍTICO: VBIOS ${vmCanonicalDir}/vbios.rom não encontrado. Abortando PREPARE." >&2
          exit 1
        fi

        # 1. Parar o gerenciador de exibição (ly / display-manager) e ollama
        ${echo} "Parando display-manager.service e ollama.service..."
        ${systemctl} stop ollama.service 2>/dev/null || true
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
        # Nota: O áudio onboard da placa-mãe (X99-P3) é um codec USB integrado (0573:1573),
        # gerenciado dinamicamente via USB passthrough no template da VM (win11-template.xml).
        ${echo} "Desvinculando áudio HDMI da GPU (0000:03:00.1)..."
        if [ -d /sys/bus/pci/drivers/snd_hda_intel/0000:03:00.1 ]; then
          ${echo} 0000:03:00.1 > /sys/bus/pci/drivers/snd_hda_intel/unbind 2>/dev/null || true
        fi

        # 7. Carregar o driver VFIO e anexar os dispositivos da GPU via sysfs
        ${echo} "Carregando vfio-pci e isolando dispositivos via sysfs..."
        if [ -e /sys/bus/pci/devices/0000:03:00.0/driver/unbind ]; then
          ${echo} 0000:03:00.0 > /sys/bus/pci/devices/0000:03:00.0/driver/unbind 2>/dev/null || true
        fi
        if [ -e /sys/bus/pci/devices/0000:03:00.1/driver/unbind ]; then
          ${echo} 0000:03:00.1 > /sys/bus/pci/devices/0000:03:00.1/driver/unbind 2>/dev/null || true
        fi
        ${modprobe} vfio-pci
        ${echo} "vfio-pci" > /sys/bus/pci/devices/0000:03:00.0/driver_override
        ${echo} "vfio-pci" > /sys/bus/pci/devices/0000:03:00.1/driver_override
        ${echo} 0000:03:00.0 > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true
        ${echo} 0000:03:00.1 > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true

        ${echo} "=== [$(${date})] GPU transferida com sucesso para o VFIO ==="
      '';

      # Script de término: Recupera a GPU do VFIO e restaura o host NixOS
      qemuHookRelease = pkgs.writeShellScript "qemu-hook-release-win11" ''
        set -euo pipefail
        LOGFILE="/var/log/libvirt/custom_hooks.log"
        ${mkdir} -p /var/log/libvirt
        exec >> "$LOGFILE" 2>&1

        ${echo} "=== [$(${date})] Iniciando gancho RELEASE (Restauração do Host) ==="

        # 1. Desvincular dispositivos do vfio-pci e limpar driver_override
        ${echo} "Desvinculando dispositivos do vfio-pci..."
        if [ -e /sys/bus/pci/drivers/vfio-pci/0000:03:00.0 ]; then
          ${echo} 0000:03:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
        fi
        if [ -e /sys/bus/pci/drivers/vfio-pci/0000:03:00.1 ]; then
          ${echo} 0000:03:00.1 > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
        fi
        ${echo} "" > /sys/bus/pci/devices/0000:03:00.0/driver_override 2>/dev/null || true
        ${echo} "" > /sys/bus/pci/devices/0000:03:00.1/driver_override 2>/dev/null || true

        # 2. Descarregar módulo vfio_pci
        ${echo} "Descarregando vfio_pci..."
        ${modprobe} -r vfio_pci 2>/dev/null || true

        # 3. Recarregar os módulos de kernel da NVIDIA (ordem direta)
        ${echo} "Recarregando módulos de kernel da NVIDIA..."
        ${modprobe} nvidia
        ${modprobe} nvidia_modeset
        ${modprobe} nvidia_uvm
        ${modprobe} nvidia_drm
        if [ ! -e /sys/bus/pci/devices/0000:03:00.0/driver ] && [ -e /sys/bus/pci/drivers/nvidia/bind ]; then
          ${echo} 0000:03:00.0 > /sys/bus/pci/drivers/nvidia/bind 2>/dev/null || true
        fi

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

        # 7. Reiniciar o gerenciador de exibição (ly) e ollama
        ${echo} "Iniciando display-manager.service e ollama.service..."
        ${systemctl} start display-manager.service || true
        ${systemctl} start ollama.service 2>/dev/null || true

        ${echo} "=== [$(${date})] Host restaurado com sucesso ==="
      '';

      dumpVbiosAndVirtioIso = pkgs.writeShellScriptBin "x99-vfio-dump" ''
        set -euo pipefail

        output_dir="${vmCanonicalDir}"
        iso_dir="$output_dir/isos"
        rom_path="/sys/bus/pci/devices/0000:03:00.0/rom"
        rom_enabled=0

        cleanup_rom() {
          if [ "$rom_enabled" -eq 1 ]; then
            printf '0\n' | ${sudo} ${pkgs.coreutils}/bin/tee "$rom_path" >/dev/null || true
          fi
        }
        trap cleanup_rom EXIT

        ${sudo} -v
        ${pkgs.coreutils}/bin/mkdir -p "$iso_dir"
        ${pkgs.coreutils}/bin/cp ${pkgs.virtio-win.src} "$iso_dir/virtio-win.iso"
        printf 'ISO do VirtIO copiada para %s\n' "$iso_dir/virtio-win.iso"

        printf '1\n' | ${sudo} ${pkgs.coreutils}/bin/tee "$rom_path" >/dev/null
        rom_enabled=1
        ${sudo} ${pkgs.coreutils}/bin/cat "$rom_path" > "$output_dir/vbios.rom"
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

        ${mkdir} -p /var/log/libvirt
        ${echo} "=== [$(${date})] Gancho QEMU invocado: guest=$GUEST_NAME op=$OPERATION sub=$SUB_OPERATION ===" >> /var/log/libvirt/custom_hooks.log

        if [ "$GUEST_NAME" = "win11" ]; then
          if [ "$OPERATION" = "prepare" ] && [ "$SUB_OPERATION" = "begin" ]; then
            ${qemuHookPrepare}
          elif [ "$OPERATION" = "release" ] && [ "$SUB_OPERATION" = "end" ]; then
            ${qemuHookRelease}
          fi
        fi
      '';

      # Scripts utilitários e idempotentes de controle da VM
      win11Start = pkgs.writeShellScriptBin "win11-start" ''
        set -euo pipefail
        VIRSH="${virsh} -c qemu:///system"

        ${echo} "=== [win11-start] Verificando estado da VM win11 ==="

        # 0. Verificação pré-voo do IOMMU no host
        if [ ! -d /sys/kernel/iommu_groups ] || [ -z "$(${pkgs.coreutils}/bin/ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
          ${echo} "ERRO CRÍTICO: Suporte a IOMMU não está ativo no host!" >&2
          ${echo} "Certifique-se de que 'intel_iommu=on' e 'iommu=pt' estão configurados nos kernelParams e o sistema foi reiniciado." >&2
          exit 1
        fi

        STATE=$($VIRSH domstate win11 2>/dev/null || true)

        if [ "$STATE" = "running" ]; then
          ${echo} "A VM 'win11' já está em execução (running). Nenhuma ação necessária."
          exit 0
        fi

        if [ "$STATE" = "paused" ]; then
          ${echo} "A VM 'win11' está pausada. Retomando..."
          $VIRSH resume win11
          ${echo} "VM 'win11' retomada com sucesso."
          exit 0
        fi

        if [ -z "$STATE" ] || [ "$STATE" = "shut off" ]; then
          if [ -f "${vmCanonicalDir}/win11-template.xml" ]; then
            ${echo} "Aplicando definição da VM 'win11' a partir de ${vmCanonicalDir}/win11-template.xml..."
            $VIRSH define "${vmCanonicalDir}/win11-template.xml"
          elif [ -f "${win11Template}" ]; then
            ${echo} "Aplicando definição da VM 'win11' a partir do template padrão do repositório..."
            $VIRSH define "${win11Template}"
          else
            if [ -z "$STATE" ]; then
              ${echo} "ERRO CRÍTICO: Template de definição ${vmCanonicalDir}/win11-template.xml não encontrado!" >&2
              exit 1
            fi
          fi
        fi

        if [ ! -f "${vmCanonicalDir}/win11.raw" ]; then
          ${echo} "ERRO CRÍTICO: Disco '${vmCanonicalDir}/win11.raw' não encontrado!" >&2
          exit 1
        fi

        if [ ! -f "${vmCanonicalDir}/vbios.rom" ]; then
          ${echo} "ERRO CRÍTICO: VBIOS '${vmCanonicalDir}/vbios.rom' não encontrado!" >&2
          exit 1
        fi

        if ! $VIRSH net-info default 2>/dev/null | ${grep} -q "Active:.*yes"; then
          ${echo} "Ativando rede virtual 'default'..."
          $VIRSH net-start default 2>/dev/null || true
        fi

        ${echo} "Iniciando a VM 'win11' (Single-GPU Passthrough)..."
        $VIRSH start win11
        ${echo} "VM 'win11' iniciada com sucesso! O display foi transferido para o Windows."
      '';

      win11Stop = pkgs.writeShellScriptBin "win11-stop" ''
        set -euo pipefail
        VIRSH="${virsh} -c qemu:///system"
        FORCE=0

        for arg in "$@"; do
          case "$arg" in
            -f|--force|force)
              FORCE=1
              ;;
            -h|--help)
              ${echo} "Uso: win11-stop [-f|--force]"
              ${echo} "  Encerra a VM win11 de forma limpa via sinal ACPI."
              ${echo} "  Use -f ou --force para forçar o desligamento imediato (virsh destroy)."
              exit 0
              ;;
          esac
        done

        STATE=$($VIRSH domstate win11 2>/dev/null || true)

        if [ "$STATE" = "shut off" ] || [ -z "$STATE" ]; then
          ${echo} "A VM 'win11' já está desligada (shut off). Nenhuma ação necessária."
          exit 0
        fi

        if [ "$FORCE" -eq 1 ]; then
          ${echo} "Forçando desligamento imediato da VM 'win11' (virsh destroy)..."
          $VIRSH destroy win11
          ${echo} "VM 'win11' desligada forçadamente. O display do host está sendo restaurado."
          exit 0
        fi

        ${echo} "Solicitando desligamento gracioso da VM 'win11' (ACPI shutdown)..."
        $VIRSH shutdown win11 2>/dev/null || true

        TIMEOUT=25
        ${echo} -n "Aguardando encerramento da VM (até ''${TIMEOUT}s)"
        while [ "$TIMEOUT" -gt 0 ]; do
          CURRENT_STATE=$($VIRSH domstate win11 2>/dev/null || true)
          if [ "$CURRENT_STATE" = "shut off" ] || [ -z "$CURRENT_STATE" ]; then
            ${echo} ""
            ${echo} "VM 'win11' desligada com sucesso! O display do host foi restaurado."
            exit 0
          fi
          ${sleep} 1
          ${echo} -n "."
          TIMEOUT=$((TIMEOUT - 1))
        done

        ${echo} ""
        ${echo} "Aviso: A VM não encerrou no tempo limite de 25s."
        ${echo} "Forçando desligamento (virsh destroy) para liberar a GPU e restaurar o host..."
        $VIRSH destroy win11
        ${echo} "VM 'win11' encerrada. O display do host foi restaurado."
      '';

      win11Status = pkgs.writeShellScriptBin "win11-status" ''
        set -euo pipefail
        VIRSH="${virsh} -c qemu:///system"

        ${echo} "=== Status da VM Windows 11 (ArcGIS Pro VFIO) ==="
        STATE=$($VIRSH domstate win11 2>/dev/null || ${echo} "não definida")
        ${echo} "Estado: $STATE"

        if [ "$STATE" = "running" ]; then
          ${echo} ""
          ${echo} "--- Detalhes da VM ---"
          $VIRSH dominfo win11 2>/dev/null | ${grep} -E "Id:|Nome:|CPU\(s\):|Memória|Estado:" || true
          ${echo} ""
          ${echo} "--- Dispositivos USB Conectados ---"
          $VIRSH qemu-monitor-command win11 --hmp "info usb" 2>/dev/null || true
          ${echo} ""
          ${echo} "--- Discos Virtuais ---"
          $VIRSH domblklist win11 2>/dev/null || true
        fi
      '';

      win11Restart = pkgs.writeShellScriptBin "win11-restart" ''
        set -euo pipefail
        ${echo} "=== [win11-restart] Reiniciando VM win11 ==="
        ${win11Stop}/bin/win11-stop "$@"
        ${sleep} 2
        ${win11Start}/bin/win11-start
      '';

      x99VfioRescue = pkgs.writeShellScriptBin "x99-vfio-rescue" ''
        set -euo pipefail
        ${echo} "=== Executando restauração de emergência da GPU / Host ==="
        ${sudo} ${pkill} -9 -f "qemu-system-x86_64" 2>/dev/null || true
        ${sudo} ${pkill} -9 -f "hooks/qemu" 2>/dev/null || true
        ${sudo} ${pkill} -9 -f "qemu-hook" 2>/dev/null || true
        ${sudo} ${pkill} -9 -f "virsh" 2>/dev/null || true
        ${sudo} ${systemctl} kill -s KILL libvirtd.service 2>/dev/null || true
        ${sleep} 1
        ${sudo} ${systemctl} restart libvirtd 2>/dev/null || true
        ${sleep} 1
        if [ -e /sys/bus/pci/drivers/vfio-pci/0000:03:00.0 ]; then
          ${echo} 0000:03:00.0 | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind >/dev/null 2>&1 || true
        fi
        if [ -e /sys/bus/pci/drivers/vfio-pci/0000:03:00.1 ]; then
          ${echo} 0000:03:00.1 | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind >/dev/null 2>&1 || true
        fi
        ${echo} "" | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/devices/0000:03:00.0/driver_override >/dev/null 2>&1 || true
        ${echo} "" | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/devices/0000:03:00.1/driver_override >/dev/null 2>&1 || true
        ${sudo} ${modprobe} -r vfio_pci 2>/dev/null || true
        ${sudo} ${modprobe} nvidia
        ${sudo} ${modprobe} nvidia_modeset
        ${sudo} ${modprobe} nvidia_uvm
        ${sudo} ${modprobe} nvidia_drm
        if [ ! -e /sys/bus/pci/devices/0000:03:00.0/driver ] && [ -e /sys/bus/pci/drivers/nvidia/bind ]; then
          ${echo} 0000:03:00.0 | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/drivers/nvidia/bind >/dev/null 2>&1 || true
        fi
        if [ -e /sys/bus/pci/drivers/snd_hda_intel/bind ]; then
          ${echo} 0000:03:00.1 | ${sudo} ${pkgs.coreutils}/bin/tee /sys/bus/pci/drivers/snd_hda_intel/bind >/dev/null 2>&1 || true
        fi
        for vt in /sys/class/vtconsole/vtcon*; do
          if [ -e "$vt/bind" ]; then
            ${echo} 1 | ${sudo} ${pkgs.coreutils}/bin/tee "$vt/bind" >/dev/null 2>&1 || true
          fi
        done
        ${sudo} ${systemctl} restart display-manager.service
        ${echo} "=== Host restaurado com sucesso ==="
      '';
    in
    {
      options.modules.x99.vfio = {
        storageDir = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/kootion512/winnt";
          description = "Caminho físico de armazenamento dos arquivos da VM Windows 11 VFIO.";
        };
      };

      config = {
        # 1. Parâmetros de Kernel (somente os relevantes para VFIO / anti-detecção).
        # Parâmetros genéricos de tuning do host ficam em x99-kernel.nix.
        boot.kernelParams = [
          # ─── IOMMU & Virtualização de Hardware ──────────────────────────
          # Requisito indispensável para isolamento e passthrough PCIe via VFIO.
          # Sem isto, o kernel não inicializa grupos DMAR e o Libvirt rejeita a VM.
          "intel_iommu=on"
          "iommu=pt"

          # ─── VETOR 1: Supressão de MSRs (KVM) ───────────────────────────
          # Sem isto, Anti-Cheat provocando leitura de MSR não implementado
          # (ex: 0x4B564D00 Hyper-V TSC, 0x40000000 Hyper-V) → #GP → BSOD.
          "kvm.ignore_msrs=1"
          # Silencia dmesg. Sem isto, cada MSR ignorado vira linha no log,
          # o que polui a observabilidade legítima do host.
          "kvm.report_ignored_msrs=0"
          # Permite passthrough de áudio HDMI em X99 sem ACS completo.
          # X99 é notorious por grupos IOMMU mal isolados — sem isto,
          # o bind de 0000:03:00.1 pode falhar silenciosamente.
          "vfio_iommu_type1.allow_unsafe_interrupts=1"

          # ─── VETOR CPUID: esconde suporte a VMX aninhado do guest. ──────
          "kvm_intel.nested=0"
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
            package = qemuGhosted;
            runAsRoot = true;
            swtpm.enable = true;
          };
        };

        # 4. Estrutura de Diretórios da VM e Injeção Declarativa do Hook
        systemd.tmpfiles.rules = [
          # Diretório dedicado físico da VM e link canônico estável
          "d ${vmStorageDir} 0775 user users - -"
          "d ${vmStorageDir}/isos 0775 user users - -"
          "L+ ${vmCanonicalDir} - - - - ${vmStorageDir}"
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
          win11Start
          win11Stop
          win11Status
          win11Restart
          x99VfioRescue
        ];

        # 6. Conexão padrão do Libvirt apontando para a instância do sistema (root)
        environment.sessionVariables = {
          LIBVIRT_DEFAULT_URI = "qemu:///system";
        };

        # 7. Aliases de terminal convenientes para gerenciar a VM no x99
        environment.shellAliases = {
          win-start = "win11-start";
          win-stop = "win11-stop";
          win-status = "win11-status";
          win-restart = "win11-restart";
          vm-start = "win11-start";
          vm-stop = "win11-stop";
          vm-status = "win11-status";
          vm-restart = "win11-restart";
        };
      };
    };
}
