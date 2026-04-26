{
  description = "Secure dev environment for the Meshtastic Python CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        secureRun = pkgs.writeShellApplication {
          name = "secure-run";
          runtimeInputs = [ pkgs.bubblewrap pkgs.bashInteractive pkgs.cacert ];
          text = ''
            set -euo pipefail

            SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            PORT_ARGS=()

            if [ -n "''${MESHTASTIC_PORT:-}" ]; then
              case "$MESHTASTIC_PORT" in
                /dev/*)
                  if [ ! -e "$MESHTASTIC_PORT" ]; then
                    echo "MESHTASTIC_PORT does not exist: $MESHTASTIC_PORT" >&2
                    exit 1
                  fi

                  PORT_ARGS+=(--dev-bind "$MESHTASTIC_PORT" "$MESHTASTIC_PORT")
                  ;;
                *)
                  echo "MESHTASTIC_PORT must be an absolute /dev path" >&2
                  exit 1
                  ;;
              esac
            fi

            exec bwrap \
              --ro-bind /nix /nix \
              --ro-bind "$MESHTASTIC_PROJECT_ROOT" "$MESHTASTIC_PROJECT_ROOT" \
              --dev /dev \
              --proc /proc \
              --bind "$PWD" /working-dir \
              --chdir /working-dir \
              --die-with-parent \
              --share-net \
              --ro-bind /etc/resolv.conf /etc/resolv.conf \
              --dir /etc --dir /etc/ssl --dir /etc/ssl/certs \
              --ro-bind "$SSL_CERT_FILE" /etc/ssl/certs/ca-bundle.crt \
              --ro-bind "$SSL_CERT_FILE" /etc/ssl/certs/ca-certificates.crt \
              --setenv SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt \
              --setenv GIT_SSL_CAINFO /etc/ssl/certs/ca-bundle.crt \
              --setenv CURL_CA_BUNDLE /etc/ssl/certs/ca-bundle.crt \
              --setenv MESHTASTIC_PORT "''${MESHTASTIC_PORT:-}" \
              "''${PORT_ARGS[@]}" \
              bash
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.python311
            pkgs.python311Packages.pip
            pkgs.bubblewrap
            pkgs.bashInteractive
            pkgs.cacert
            pkgs.git
            pkgs.which
            secureRun
          ];

          shellHook = ''
            if [ -f "$PWD/meshtastic/flake.nix" ]; then
              export MESHTASTIC_PROJECT_ROOT="$PWD/meshtastic"
            else
              export MESHTASTIC_PROJECT_ROOT="$PWD"
            fi

            VENV_DIR="$MESHTASTIC_PROJECT_ROOT/.venv"

            if [ ! -d "$VENV_DIR" ]; then
              echo "Creating Meshtastic virtualenv in $VENV_DIR"
              python -m venv "$VENV_DIR"
            fi

            . "$VENV_DIR/bin/activate"

            if ! pip show meshtastic >/dev/null 2>&1; then
              pip install --upgrade pip
              pip install "meshtastic[cli]"
            fi

            if [ -n "''${MESHTASTIC_PORT:-}" ]; then
              echo "Meshtastic CLI ready for $MESHTASTIC_PORT"
            else
              echo "Meshtastic CLI ready. Set MESHTASTIC_PORT=/dev/ttyUSB0 before running secure-run to expose a serial device."
            fi
          '';
        };
      }
    );
}
