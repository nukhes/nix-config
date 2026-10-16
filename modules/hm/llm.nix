{ inputs, lib, ... }:

let
  # ============================================================================
  # Catálogo Único de Modelos (Single Source of Truth)
  # Alterar aqui sincroniza automaticamente:
  #   1. O serviço NixOS do Ollama (download automático via loadModels)
  #   2. O prompt CLI rápido (gemini-repl · Super+Shift+G / Super+Shift+S)
  #   3. O OpenCode (~/.config/opencode/opencode.json · providers ollama & google)
  # ============================================================================
  defaultGeminiModel = "gemini-3-flash-preview";

  ollamaModels = [
    {
      id = "qwen2.5-coder:3b";
      name = "Qwen 2.5 Coder 3B (Rápido · CPU/GPU)";
      desc = "local · ~1.9GB · código rápido";
      tool_call = true;
      reasoning = false;
      vision = false;
    }
    {
      id = "llama3.2:3b";
      name = "Llama 3.2 3B (Chat Rápido · CPU/GPU)";
      desc = "local · ~2.0GB · chat ultra-rápido";
      tool_call = true;
      reasoning = false;
      vision = false;
    }
    {
      id = "gemma3:4b";
      name = "Gemma 3 4B (Visão / Screenshots)";
      desc = "local · ~3.1GB · multimodal/visão";
      tool_call = false;
      reasoning = false;
      vision = true;
    }
    {
      id = "qwen2.5-coder:7b";
      name = "Qwen 2.5 Coder 7B (Xeon 32GB)";
      desc = "local · ~4.4GB · código (Xeon)";
      tool_call = true;
      reasoning = false;
      vision = false;
    }
    {
      id = "deepseek-r1:8b";
      name = "DeepSeek R1 8B (Raciocínio · Xeon 32GB)";
      desc = "local · ~4.9GB · raciocínio (Xeon)";
      tool_call = false;
      reasoning = true;
      vision = false;
    }
    {
      id = "cognitivecomputations/dolphin-mistral-nemo:12b";
      name = "Dolphin 2.9.4 Mistral Nemo 12B (Uncensored · Xeon 32GB)";
      desc = "local · ~7.0GB · uncensored 12B (Xeon)";
      tool_call = true;
      reasoning = false;
      vision = false;
    }
    {
      id = "qwen2.5:14b";
      name = "Qwen 2.5 14B (Alta Capacidade · Xeon 32GB)";
      desc = "local · ~9.0GB · alta capacidade (Xeon)";
      tool_call = true;
      reasoning = false;
      vision = false;
    }
  ];

  geminiModels = [
    {
      id = "gemini-3-flash-preview";
      name = "Gemini 3 Flash (Rápido + Visão)";
      desc = "cloud · rápido + visão (recomendado)";
    }
    {
      id = "gemini-3.1-flash-lite-preview";
      name = "Gemini 3.1 Flash Lite (Ultra-rápido)";
      desc = "cloud · ultra-rápido";
    }
    {
      id = "gemini-3.1-pro-preview";
      name = "Gemini 3.1 Pro (Raciocínio Avançado)";
      desc = "cloud · raciocínio avançado";
    }
    {
      id = "gemini-2.5-flash-lite";
      name = "Gemini 2.5 Flash Lite";
      desc = "cloud · leve";
    }
    {
      id = "gemini-2.5-pro";
      name = "Gemini 2.5 Pro";
      desc = "cloud · pro";
    }
    {
      id = "gemini-3.8-flash";
      name = "Gemini 3.8 Flash (Thinking)";
      desc = "cloud · thinking";
    }
  ];

  geminiCatalogLines = lib.concatMapStringsSep "\n" (m: "${m.id}\t${m.desc}") geminiModels;
  ollamaCatalogLines = lib.concatMapStringsSep "\n" (m: "ollama:${m.id}\t${m.desc}") ollamaModels;
in
{
  # 1. Serviço NixOS (x99): Ollama sincronizado com a lista única
  nixos.modules.x99 =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        loadModels = map (m: m.id) ollamaModels;
        environmentVariables = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_CONTEXT_LENGTH = "16384";
          OLLAMA_KEEP_ALIVE = "30m";
        };
      };

      systemd.services.ollama.serviceConfig.MemoryDenyWriteExecute = lib.mkForce false;
    };

  # 2. Home Manager: gemini-repl + OpenCode sincronizados com a mesma lista
  hm.modules.common =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.home) homeDirectory;
      inherit (config.xdg) configHome;
      inherit (pkgs.stdenv.hostPlatform) isLinux;

      geminiKeyPath = "${homeDirectory}/.secrets/google/henriquealvesp052/gemini-api";

      gemini-repl = pkgs.writeShellApplication {
        name = "gemini-repl";
        runtimeInputs =
          with pkgs;
          [
            curl
            jq
            bat
            fzf
            coreutils
            gnugrep
          ]
          ++ lib.optionals isLinux [
            maim
            xclip
          ];
        text = ''
          MODEL="''${GEMINI_MODEL:-${defaultGeminiModel}}"
          OLLAMA_HOST="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
          HW_MODE="''${OLLAMA_HW_MODE:-cpu}" # padrao cpu (Xeon E5-2676 12c, 32GB DDR4); gpu usa GTX 960 Vulkan
          CPU_THREADS="''${OLLAMA_CPU_THREADS:-12}"

          KEY_FILE="${geminiKeyPath}"
          API_KEY="''${GEMINI_API_KEY:-}"
          if [ -z "$API_KEY" ] && [ -f "$KEY_FILE" ]; then
            API_KEY="$(cat "$KEY_FILE")"
          fi

          SESSION_DIR="$(mktemp -d /tmp/gemini-repl.XXXXXX)"
          CLEANUP_DIR=""
          GEMINI_HISTORY="$SESSION_DIR/gemini_history.json"
          OLLAMA_HISTORY="$SESSION_DIR/ollama_history.json"
          printf '[]' > "$GEMINI_HISTORY"
          printf '[]' > "$OLLAMA_HISTORY"
          LAST_REPLY=""
          IMG_COUNTER=0
          declare -a PENDING_IMAGES=()
          declare -a PROMPT_ARGS=()

          cleanup() {
            rm -rf "$SESSION_DIR"
            if [ -n "$CLEANUP_DIR" ] && [ -d "$CLEANUP_DIR" ]; then
              rm -rf "$CLEANUP_DIR"
            fi
          }
          trap cleanup EXIT

          while [ "$#" -gt 0 ]; do
            case "$1" in
              -i|--image)
                if [ -n "''${2:-}" ] && [ -f "$2" ]; then
                  PENDING_IMAGES+=("$2")
                fi
                shift 2
                ;;
              -d|--cleanup-dir)
                CLEANUP_DIR="''${2:-}"
                shift 2
                ;;
              -m|--model)
                MODEL="''${2:-$MODEL}"
                shift 2
                ;;
              --hw)
                HW_MODE="''${2:-$HW_MODE}"
                shift 2
                ;;
              --)
                shift
                PROMPT_ARGS+=("$@")
                break
                ;;
              *)
                PROMPT_ARGS+=("$1")
                shift
                ;;
            esac
          done

          INITIAL_PROMPT="''${PROMPT_ARGS[*]:-}"

          is_ollama_model() {
            case "$1" in
              ollama:*|gemma*|qwen*|llama*|deepseek*|dolphin*|cognitivecomputations/*|mistral*|phi*|llava*|codellama*|*:*)
                return 0
                ;;
              *)
                return 1
                ;;
            esac
          }

          normalize_model() {
            local m="$1"
            if is_ollama_model "$m" && [[ "$m" != ollama:* ]]; then
              printf 'ollama:%s' "$m"
            else
              printf '%s' "$m"
            fi
          }

          MODEL="$(normalize_model "$MODEL")"

          fetch_ollama_models() {
            local catalog live
            catalog="$(cat << 'EOF'
          ${ollamaCatalogLines}
          EOF
            )"
            live="$(
              curl -s --connect-timeout 1 --max-time 2 "$OLLAMA_HOST/api/tags" 2>/dev/null \
                | jq -r '.models[]? | "ollama:\(.name)\tlocal · \((.size / 1073741824 * 10 | round) / 10)GB (\(.details.quantization_level // "gguf"))"' 2>/dev/null || true
            )"
            if [ -n "$live" ]; then
              # Mostra todos os modelos já baixados no Ollama + os do catálogo ainda em download
              {
                printf '%s\n' "$live"
                while IFS=$'\t' read -r c_name c_desc; do
                  [ -z "$c_name" ] && continue
                  if ! printf '%s\n' "$live" | cut -f1 | grep -qxF "$c_name"; then
                    printf '%s\t%s (baixando/pendente)\n' "$c_name" "$c_desc"
                  fi
                done <<< "$catalog"
              }
            else
              printf '%s\n' "$catalog"
            fi
          }

          fetch_gemini_models() {
            cat << 'EOF'
          ${geminiCatalogLines}
          EOF
          }

          build_all_models() {
            fetch_ollama_models
            fetch_gemini_models
          }

          list_models() {
            local idx=1
            printf '\033[1;34m── modelos disponíveis (hw local: %s · %s threads) ──\033[0m\n' "$HW_MODE" "$CPU_THREADS"
            while IFS=$'\t' read -r m_name m_info; do
              [ -z "$m_name" ] && continue
              if [ "$m_name" = "$MODEL" ]; then
                printf '  \033[1;32m* [%2d] %-48s\033[0m \033[2m%s\033[0m\n' "$idx" "$m_name" "$m_info"
              else
                printf '    [%2d] %-48s \033[2m%s\033[0m\n' "$idx" "$m_name" "$m_info"
              fi
              idx=$((idx + 1))
            done < <(build_all_models)
            printf '\033[2mdica: digite "/model" (seletor fzf), "/model <número>" (ex: /model 1) ou "/model <nome>" (ex: /model dolphin)\033[0m\n'
          }

          switch_model() {
            local query="''${1:-}"
            local all_lines
            all_lines="$(build_all_models)"

            if [ -z "$query" ]; then
              local choice=""
              choice="$(
                printf '%s\n' "$all_lines" \
                  | fzf --height=45% --reverse --prompt="model ($HW_MODE) > " --with-nth=1,2 --delimiter=$'\t'
              )" || return 0
              local picked="''${choice%%$'\t'*}"
              if [ -n "$picked" ]; then
                MODEL="$(normalize_model "$picked")"
                printf '\033[1;32m✓\033[0m \033[2mmodelo ativo:\033[0m %s\n' "$MODEL"
              fi
              return 0
            fi

            if [[ "$query" =~ ^[0-9]+$ ]]; then
              local idx=1
              while IFS=$'\t' read -r m_name _; do
                [ -z "$m_name" ] && continue
                if [ "$idx" -eq "$query" ]; then
                  MODEL="$m_name"
                  printf '\033[1;32m✓\033[0m \033[2mmodelo ativo:\033[0m %s\n' "$MODEL"
                  return 0
                fi
                idx=$((idx + 1))
              done <<< "$all_lines"
              printf '\033[1;33míndice %s inválido (use /list para ver os números)\033[0m\n' "$query"
              return 1
            fi

            local match=""
            match="$(printf '%s\n' "$all_lines" | cut -f1 | grep -iF "$query" | head -n1 || true)"
            if [ -n "$match" ]; then
              MODEL="$(normalize_model "$match")"
            else
              MODEL="$(normalize_model "$query")"
            fi
            printf '\033[1;32m✓\033[0m \033[2mmodelo ativo:\033[0m %s\n' "$MODEL"
          }

          append_shared_history() {
            local user_text="$1"
            local reply_text="$2"
            local gemini_parts_file="$3"
            local ollama_images_file="$4"
            local raw_gemini_content_file="$5"

            jq --slurpfile parts "$gemini_parts_file" \
              '. + [{"role": "user", "parts": $parts[0]}]' \
              "$GEMINI_HISTORY" > "$GEMINI_HISTORY.tmp"
            mv "$GEMINI_HISTORY.tmp" "$GEMINI_HISTORY"

            if [ -n "$raw_gemini_content_file" ] && [ -f "$raw_gemini_content_file" ]; then
              jq --slurpfile content "$raw_gemini_content_file" \
                '. + [$content[0]]' \
                "$GEMINI_HISTORY" > "$GEMINI_HISTORY.tmp"
            else
              jq --arg text "$reply_text" \
                '. + [{"role": "model", "parts": [{"text": $text}]}]' \
                "$GEMINI_HISTORY" > "$GEMINI_HISTORY.tmp"
            fi
            mv "$GEMINI_HISTORY.tmp" "$GEMINI_HISTORY"

            jq --arg text "$user_text" --slurpfile imgs "$ollama_images_file" \
              '. + [if ($imgs[0] | length) > 0 then {"role": "user", "content": $text, "images": $imgs[0]} else {"role": "user", "content": $text} end]' \
              "$OLLAMA_HISTORY" > "$OLLAMA_HISTORY.tmp"
            mv "$OLLAMA_HISTORY.tmp" "$OLLAMA_HISTORY"

            jq --arg text "$reply_text" \
              '. + [{"role": "assistant", "content": $text}]' \
              "$OLLAMA_HISTORY" > "$OLLAMA_HISTORY.tmp"
            mv "$OLLAMA_HISTORY.tmp" "$OLLAMA_HISTORY"
          }

          send_turn() {
            local user_text="$1"
            local gemini_parts_file="$SESSION_DIR/gemini_parts.json"
            local ollama_images_file="$SESSION_DIR/ollama_images.json"
            printf '[]' > "$gemini_parts_file"
            printf '[]' > "$ollama_images_file"

            for img in "''${PENDING_IMAGES[@]}"; do
              if [ -f "$img" ]; then
                local b64_file="$SESSION_DIR/img.b64"
                base64 -w0 "$img" > "$b64_file"
                jq --rawfile data "$b64_file" \
                  '. + [{"inline_data": {"mime_type": "image/png", "data": ($data | rtrimstr("\n"))}}]' \
                  "$gemini_parts_file" > "$gemini_parts_file.tmp"
                mv "$gemini_parts_file.tmp" "$gemini_parts_file"

                jq --rawfile data "$b64_file" \
                  '. + [($data | rtrimstr("\n"))]' \
                  "$ollama_images_file" > "$ollama_images_file.tmp"
                mv "$ollama_images_file.tmp" "$ollama_images_file"
                rm -f "$b64_file"
              fi
            done

            jq --arg text "$user_text" \
              '. + [{"text": $text}]' \
              "$gemini_parts_file" > "$gemini_parts_file.tmp"
            mv "$gemini_parts_file.tmp" "$gemini_parts_file"

            local req_file="$SESSION_DIR/request.json"
            local resp_file="$SESSION_DIR/response.json"
            local reply_text=""
            local raw_gemini_content=""

            if [[ "$MODEL" == ollama:* ]]; then
              local ollama_model="''${MODEL#ollama:}"
              local num_gpu=0
              if [ "$HW_MODE" = "gpu" ]; then
                num_gpu=-1
              fi

              jq --arg model "$ollama_model" \
                --arg text "$user_text" \
                --slurpfile imgs "$ollama_images_file" \
                --argjson num_gpu "$num_gpu" \
                --argjson num_thread "$CPU_THREADS" \
                '{
                  model: $model,
                  stream: true,
                  options: {
                    num_gpu: $num_gpu,
                    num_thread: $num_thread
                  },
                  messages: (. + [
                    if ($imgs[0] | length) > 0 then
                      {"role": "user", "content": $text, "images": $imgs[0]}
                    else
                      {"role": "user", "content": $text}
                    end
                  ])
                }' "$OLLAMA_HISTORY" > "$req_file"

              printf '\033[2m... carregando %s (%s)\033[0m\r\033[K\n' "$ollama_model" "$HW_MODE"
              : > "$resp_file"

              if ! curl -sS -N --connect-timeout 5 --max-time 600 "$OLLAMA_HOST/api/chat" \
                -H 'Content-Type: application/json' \
                --data-binary @"$req_file" \
                | tee "$resp_file" \
                | jq --unbuffered -j '.message.content // empty'; then
                printf '\n\033[1;31merro ao conectar ao Ollama em %s (serviço ativo?)\033[0m\n' "$OLLAMA_HOST"
                return 1
              fi
              printf '\n\n'

              local err_msg
              err_msg="$(jq -r '.error // empty' "$resp_file" 2>/dev/null | head -n1 || true)"
              if [ -n "$err_msg" ]; then
                printf '\033[1;31merro ollama (%s):\033[0m %s\n' "$ollama_model" "$err_msg"
                return 1
              fi

              reply_text="$(jq -rs '[.[].message.content // empty] | join("")' "$resp_file" 2>/dev/null || true)"

              if [ -z "$reply_text" ]; then
                printf '\033[1;33m(resposta vazia)\033[0m\n'
                return 1
              fi

              append_shared_history "$user_text" "$reply_text" "$gemini_parts_file" "$ollama_images_file" ""
              PENDING_IMAGES=()
              LAST_REPLY="$reply_text"
              return 0
            else
              if [ -z "$API_KEY" ]; then
                printf '\033[1;31merro:\033[0m GEMINI_API_KEY não encontrada em %s (use /model para escolher ollama local)\n' "$KEY_FILE"
                return 1
              fi

              jq --slurpfile parts "$gemini_parts_file" \
                '{
                  contents: (. + [{"role": "user", "parts": $parts[0]}]),
                  generationConfig: {
                    thinkingConfig: {
                      thinkingBudget: 0
                    }
                  }
                }' "$GEMINI_HISTORY" > "$req_file"

              printf '\033[2m...\033[0m'
              local url="https://generativelanguage.googleapis.com/v1beta/models/''${MODEL}:generateContent?key=''${API_KEY}"

              if ! curl -4 -sS --retry 2 --retry-delay 1 --connect-timeout 10 --max-time 120 "$url" \
                -H 'Content-Type: application/json' \
                --data-binary @"$req_file" > "$resp_file"; then
                printf '\r\033[K\033[1;31merro de rede ao conectar à API do Gemini (use /model 1 para usar Ollama offline)\033[0m\n'
                return 1
              fi

              printf '\r\033[K'

              local err_msg
              err_msg="$(jq -r '.error.message // empty' "$resp_file")"
              if [ -n "$err_msg" ]; then
                printf '\033[1;31merro (%s):\033[0m %s\n' "$MODEL" "$err_msg"
                return 1
              fi

              reply_text="$(jq -r '[.candidates[0].content.parts[]? | select(.text != null) | .text] | join("\n")' "$resp_file")"
              raw_gemini_content="$SESSION_DIR/gemini_content.json"
              jq '.candidates[0].content' "$resp_file" > "$raw_gemini_content"
            fi

            if [ -z "$reply_text" ]; then
              printf '\033[1;33m(resposta vazia)\033[0m\n'
              return 1
            fi

            append_shared_history "$user_text" "$reply_text" "$gemini_parts_file" "$ollama_images_file" "$raw_gemini_content"

            PENDING_IMAGES=()
            LAST_REPLY="$reply_text"

            printf '\n'
            printf '%s\n' "$reply_text" | bat --style=plain --language=markdown --color=always --paging=never
            printf '\n'
          }

          print_banner() {
            if [[ "$MODEL" == ollama:* ]]; then
              printf '\033[2mgemini-repl (%s [%s]) · /list /model /hw /img /clip /copy /clear /q\033[0m\n' "$MODEL" "$HW_MODE"
            else
              printf '\033[2mgemini-repl (%s) · /list /model /hw /img /clip /copy /clear /q\033[0m\n' "$MODEL"
            fi
          }

          print_banner

          if [ -n "$INITIAL_PROMPT" ]; then
            if [ "''${#PENDING_IMAGES[@]}" -gt 0 ]; then
              printf '\033[1;33m[%d img]\033[0m \033[1;34m>\033[0m %s\n' "''${#PENDING_IMAGES[@]}" "$INITIAL_PROMPT"
            else
              printf '\033[1;34m>\033[0m %s\n' "$INITIAL_PROMPT"
            fi
            send_turn "$INITIAL_PROMPT" || true
          fi

          while true; do
            if [[ "$MODEL" == ollama:* ]]; then
              model_tag=$'\001\033[2m\002('"''${MODEL#ollama:}"$'·'"$HW_MODE"$') \001\033[0m\002'
            else
              model_tag=$'\001\033[2m\002('"$MODEL"$') \001\033[0m\002'
            fi

            if [ "''${#PENDING_IMAGES[@]}" -gt 0 ]; then
              prompt_str="''${model_tag}"$'\001\033[1;33m\002['"''${#PENDING_IMAGES[@]}"$' img]\001\033[0m\002 \001\033[1;34m\002>\001\033[0m\002 '
            else
              prompt_str="''${model_tag}"$'\001\033[1;34m\002>\001\033[0m\002 '
            fi

            if ! IFS= read -r -e -p "$prompt_str" line; then
              printf '\n'
              break
            fi

            [ -z "$line" ] && continue
            history -s "$line"

            case "$line" in
              /q|/quit|exit)
                break
                ;;
              /clear|/c)
                printf '[]' > "$GEMINI_HISTORY"
                printf '[]' > "$OLLAMA_HISTORY"
                PENDING_IMAGES=()
                clear
                print_banner
                ;;
              /list|/models|/ls|list|models)
                list_models
                ;;
              /model|model)
                switch_model "" || true
                ;;
              /model\ *|model\ *)
                target_model="''${line#* }"
                target_model="''${target_model#"''${target_model%%[![:space:]]*}"}"
                switch_model "$target_model" || true
                ;;
              /hw|/device)
                if [ "$HW_MODE" = "gpu" ]; then
                  HW_MODE="cpu"
                  printf '\033[2mmodo hardware ollama: cpu (Xeon E5-2676 v3 · %s threads, 32GB DDR4)\033[0m\n' "$CPU_THREADS"
                else
                  HW_MODE="gpu"
                  printf '\033[2mmodo hardware ollama: gpu (GTX 960 Vulkan + Xeon E5-2676 v3)\033[0m\n'
                fi
                ;;
              /hw\ *|/device\ *)
                arg_hw="''${line#* }"
                case "$arg_hw" in
                  gpu|gtx|vulkan)
                    HW_MODE="gpu"
                    printf '\033[2mmodo hardware ollama: gpu (GTX 960 Vulkan + Xeon E5-2676 v3)\033[0m\n'
                    ;;
                  cpu|xeon)
                    HW_MODE="cpu"
                    printf '\033[2mmodo hardware ollama: cpu (Xeon E5-2676 v3 · %s threads, 32GB DDR4)\033[0m\n' "$CPU_THREADS"
                    ;;
                  *)
                    printf '\033[2muso: /hw [cpu|gpu]\033[0m\n'
                    ;;
                esac
                ;;
              /copy|/y)
                if [ -n "$LAST_REPLY" ]; then
                  printf '%s' "$LAST_REPLY" | xclip -selection clipboard
                  printf '\033[2m✓ resposta copiada para o clipboard\033[0m\n'
                else
                  printf '\033[2mnenhuma resposta para copiar\033[0m\n'
                fi
                ;;
              /img|/s)
                IMG_COUNTER=$((IMG_COUNTER + 1))
                shot="$SESSION_DIR/shot-$IMG_COUNTER.png"
                if maim -s "$shot" 2>/dev/null; then
                  PENDING_IMAGES+=("$shot")
                  printf '\033[2m+ screenshot anexado (%d no total)\033[0m\n' "''${#PENDING_IMAGES[@]}"
                else
                  rm -f "$shot"
                  printf '\033[2mcaptura cancelada\033[0m\n'
                fi
                ;;
              /clip)
                IMG_COUNTER=$((IMG_COUNTER + 1))
                shot="$SESSION_DIR/clip-$IMG_COUNTER.png"
                if xclip -selection clipboard -t image/png -o > "$shot" 2>/dev/null && [ -s "$shot" ]; then
                  PENDING_IMAGES+=("$shot")
                  printf '\033[2m+ imagem do clipboard anexada (%d no total)\033[0m\n' "''${#PENDING_IMAGES[@]}"
                else
                  rm -f "$shot"
                  printf '\033[2mnenhuma imagem PNG no clipboard\033[0m\n'
                fi
                ;;
              /drop)
                PENDING_IMAGES=()
                printf '\033[2manexos pendentes removidos\033[0m\n'
                ;;
              /help|\?|help)
                printf '\033[2mcomandos:\n'
                printf '  /list (/ls)     listar modelos numerados (Ollama local + Gemini cloud)\n'
                printf '  /model [n|nome] seletor fzf, ou trocar por número (/model 1) ou nome (/model dolphin)\n'
                printf '  /hw [cpu|gpu]   alternar Ollama entre Xeon E5-2676 32GB (cpu) e GTX 960 (gpu)\n'
                printf '  /img (/s)       capturar área da tela e anexar\n'
                printf '  /clip           anexar imagem atual do clipboard\n'
                printf '  /drop           remover imagens pendentes não enviadas\n'
                printf '  /copy (/y)      copiar última resposta para o clipboard\n'
                printf '  /clear (/c)     limpar conversa efêmera\n'
                printf '  /q (Ctrl+D)     sair\033[0m\n'
                ;;
              *)
                send_turn "$line" || true
                ;;
            esac
          done
        '';
      };
    in
    {
      home.packages = [
        inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
        gemini-repl
      ];

      home.file.".gemini/antigravity-cli/settings.json" = {
        force = true;
        text = builtins.toJSON {
          agentMode = "accept-edits";
          artifactReviewPolicy = "always-proceed";
          toolPermission = "always-proceed";

          allowNonWorkspaceAccess = true;
          trustedWorkspaces = [ ];

          permissions = {
            allow = [ "command(*)" ];
          };

          editor = "vim";
          editorMode = "vim";
          enableTelemetry = false;
          model = "Claude Opus 4.6 (Thinking)";
          runningLightSpeed = "off";
          showFeedbackSurvey = false;
          showTips = false;
          verbosity = "low";
        };
      };

      home.shellAliases = {
        agy = "agy --dangerously-skip-permissions";
      };

      programs.claude-code = {
        enable = true;
        configDir = "${configHome}/claude";
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        validateFiles.config = true;
        settings = {
          model = "google/${defaultGeminiModel}";
          small_model = "google/gemini-3.1-flash-lite-preview";
          provider = {
            google = {
              options = {
                apiKey = "{file:${geminiKeyPath}}";
              };
              whitelist = map (m: m.id) geminiModels;
            };
            ollama = {
              npm = "@ai-sdk/openai-compatible";
              name = "Ollama (Local Xeon E5-2676 / GTX 960)";
              options = {
                baseURL = "http://127.0.0.1:11434/v1";
              };
              models = builtins.listToAttrs (
                map (m: {
                  name = m.id;
                  value = {
                    inherit (m) name tool_call reasoning;
                    attachment = m.vision;
                    limit = {
                      context = 16384;
                      output = 8192;
                    };
                  };
                }) ollamaModels
              );
            };
          };
        };
      };

      age.secrets.gemini-p052 = {
        file = "${homeDirectory}/.nix-config/secrets/google/henriquealvesp052/gemini-api.age";
        path = geminiKeyPath;
        mode = "0600";
      };
    };
}
