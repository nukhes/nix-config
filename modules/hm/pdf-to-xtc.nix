_:

{
  hm.modules.common =
    { lib, pkgs, ... }:
    let
      # Pinned upstream snapshot (not on PyPI). Fetched and run ephemerally by uvx.
      xtctoolSrc = "https://github.com/chazeon/xtctool/archive/d7bff34ff835889e158ca8ff2253de06a3e825cf.tar.gz";

      # manylinux wheels (numpy, PyMuPDF) expect FHS libs; exposed to uvx only.
      wheelLibs = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
      ];

      # hatchling >= 1.28 rejects upstream's duplicated force-include entry.
      buildConstraints = pkgs.writeText "xtctool-build-constraints.txt" ''
        hatchling<1.28
      '';

      # Loaded automatically by Python via PYTHONPATH:
      # 1. Restores default SIGINT so Ctrl-C kills the batch instead of click turning it into exit(1).
      # 2. Vectorizes XTHWriter._encode_bitplanes with np.packbits (~88x faster, bit-identical).
      # 3. Caches fitz.open() per PDF instead of reopening the file on every page.
      siteCustomize = pkgs.writeTextDir "sitecustomize.py" ''
        import signal
        import warnings

        signal.signal(signal.SIGINT, signal.SIG_DFL)
        warnings.filterwarnings("ignore", category=FutureWarning)

        try:
            import fitz
            import numpy as np
            from PIL import Image
            from xtctool.core.xth import XTHWriter
            from xtctool.utils.pdf import PDFConverter

            _LUT = np.array([3, 1, 2, 0], dtype=np.uint8)

            def _fast_encode_bitplanes(self, pixel_values):
                mapped = _LUT[pixel_values][:, ::-1].T
                b1 = np.packbits((mapped >> 1) & 1, axis=1).tobytes()
                b2 = np.packbits(mapped & 1, axis=1).tobytes()
                return bytearray(b1), bytearray(b2)

            XTHWriter._encode_bitplanes = _fast_encode_bitplanes

            _doc_cache = {}

            def _get_doc(pdf_path):
                doc = _doc_cache.get(pdf_path)
                if doc is None or getattr(doc, "is_closed", False):
                    for old in _doc_cache.values():
                        try:
                            old.close()
                        except Exception:
                            pass
                    _doc_cache.clear()
                    doc = fitz.open(pdf_path)
                    _doc_cache[pdf_path] = doc
                return doc

            def _fast_get_page_count(self, pdf_path):
                return len(_get_doc(pdf_path))

            def _fast_render_page(self, pdf_path, page_num):
                doc = _get_doc(pdf_path)
                page_idx = page_num - 1
                if page_idx < 0 or page_idx >= len(doc):
                    raise ValueError(f"Page {page_num} out of range (1-{len(doc)})")
                pix = doc[page_idx].get_pixmap(matrix=fitz.Matrix(self.zoom, self.zoom))
                return Image.frombytes("RGB", (pix.width, pix.height), pix.samples)

            PDFConverter.get_page_count = _fast_get_page_count
            PDFConverter.render_page = _fast_render_page
        except Exception:
            pass
      '';

      # 2-bit / 4-level grayscale (XTH) pages for the Xteink X4 (480x800).
      # No dithering + near-white cutoff keeps thin lines and diagrams crisp:
      # BOX downsampling turns hairlines into gray instead of dropping them,
      # and anything darker than 245 survives as at least light gray.
      xtctoolConfig = (pkgs.formats.toml { }).generate "xtctool.toml" {
        output = {
          format = "xth";
          width = 480;
          height = 800;
          resample_method = "BOX";
        };
        xth = {
          dither = false;
          threshold1 = 85;
          threshold2 = 170;
          threshold3 = 245;
        };
      };

      pdfToXtc = pkgs.writeShellApplication {
        name = "pdf-to-xtc";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.qpdf
          pkgs.uv
        ];

        text = ''
          usage() {
            cat <<'EOF'
          Usage: pdf-to-xtc <PDF_DIR> [OUT_DIR]

          Convert every *.pdf in PDF_DIR (case-insensitive, non-recursive) to
          Xteink .xtch (XTC container with 2-bit / 4-level grayscale pages, 480x800).

            PDF_DIR   directory with the PDFs
            OUT_DIR   destination directory (default: PDF_DIR/xtc-out)

          xtctool runs ephemerally via uvx; its cache lives in a temp dir
          that is removed on exit.
          EOF
          }

          case "''${1:-}" in
            -h | --help)
              usage
              exit 0
              ;;
          esac

          if [ "$#" -lt 1 ] || [ "$#" -gt 2 ] || [ ! -d "$1" ]; then
            usage >&2
            exit 1
          fi

          src="''${1%/}"
          src="''${src:-/}"
          out="''${2:-}"
          out="''${out:-$src/xtc-out}"

          mapfile -d "" pdfs < <(find "$src" -maxdepth 1 -type f -iname '*.pdf' -print0 | sort -z)

          if [ "''${#pdfs[@]}" -eq 0 ]; then
            echo "pdf-to-xtc: no PDFs found in $src" >&2
            exit 1
          fi

          mkdir -p "$out"

          work="$(mktemp -d)"
          trap 'rm -rf "$work"' EXIT
          # xtctool turns SIGINT into a plain exit 1; abort the batch, not just one file.
          trap 'exit 130' INT TERM

          export UV_CACHE_DIR="$work/uv"
          export UV_PYTHON="${pkgs.python3}/bin/python3"
          export UV_PYTHON_DOWNLOADS=never
          export UV_NO_CONFIG=1
          export PYTHONWARNINGS=ignore
          export PYTHONPATH="${siteCustomize}''${PYTHONPATH:+:$PYTHONPATH}"
          ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            export LD_LIBRARY_PATH="${wheelLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          ''}

          # xtctool keeps every rendered page of a source in RAM; feeding it page
          # ranges caps that at one chunk while still producing a single file.
          chunk=50
          total="''${#pdfs[@]}"
          n=0
          failed=0

          for pdf in "''${pdfs[@]}"; do
            n=$((n + 1))
            name="$(basename "$pdf")"
            dest="$out/''${name%.*}.xtch"

            # xtctool parses "file:1-4" page specs, so feed it a neutral path.
            ln -sfn "$(realpath "$pdf")" "$work/in.pdf"
            rm -f "$work/out.xtc"

            if ! pages="$(qpdf --warning-exit-0 --show-npages "$work/in.pdf" 2>/dev/null)"; then
              failed=$((failed + 1))
              echo "[$n/$total] $name FAILED (unreadable PDF)" >&2
              continue
            fi

            ranges=()
            for ((s = 1; s <= pages; s += chunk)); do
              e=$((s + chunk - 1 > pages ? pages : s + chunk - 1))
              ranges+=("$work/in.pdf:$s-$e")
            done

            echo "[$n/$total] $name ($pages pages)"

            if uvx --quiet \
              --build-constraints ${buildConstraints} \
              --from "xtctool[markdown] @ ${xtctoolSrc}" \
              xtctool convert -c ${xtctoolConfig} -o "$work/out.xtc" "''${ranges[@]}" \
              >/dev/null && [ -s "$work/out.xtc" ]; then
              # XTCH == XTC with mark "XTCH" instead of "XTC\0".
              printf 'H' | dd of="$work/out.xtc" bs=1 seek=3 count=1 conv=notrunc status=none
              mv -f "$work/out.xtc" "$dest"
              echo "  -> $dest"
            else
              failed=$((failed + 1))
              echo "  FAILED" >&2
            fi
          done

          if [ "$failed" -gt 0 ]; then
            echo "pdf-to-xtc: $failed of $total failed" >&2
            exit 1
          fi
        '';
      };
    in
    {
      home.packages = [
        pdfToXtc
      ];
    };
}
