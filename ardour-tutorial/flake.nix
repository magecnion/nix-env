{
  description = "Dev environment for ardour-tutorial (pinned Go + pinned Hugo)";

  inputs = {
    # Pin nixpkgs to a revision where go_1_23 is 1.23.6. :contentReference[oaicite:2]{index=2}
    nixpkgs.url = "github:NixOS/nixpkgs/0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        go = pkgs.go_1_23;

        # Hugo pinned to v0.138.0 (built from source). :contentReference[oaicite:3]{index=3}
        hugo_0_138_0 = pkgs.buildGoModule rec {
          pname = "hugo";
          version = "0.138.0";

          src = pkgs.fetchFromGitHub {
            owner = "gohugoio";
            repo = "hugo";
            rev = "v${version}";

            # Step 3 will tell you how to fill these hashes in.
            hash = "sha256-IDWQRPJrTCkvcTcsaGuyQraVoWWUe0d6FTQvvYHZcD0=";
          };

          inherit go;

          # First run will fail and print the correct vendorHash.
          vendorHash = "sha256-N48HocNo5gsDpTsGLvK1WNuTkjr3wFGW6UuR8NPiPLk=";

          subPackages = [ "." ];

          ldflags = [
            "-s" "-w"
            "-X github.com/gohugoio/hugo/common/hugo.vendorInfo=nix"
          ];

          doCheck = false;
        };

        secureRun = pkgs.writeShellApplication {
          name = "secure-run";
          runtimeInputs = [ pkgs.bubblewrap pkgs.bashInteractive pkgs.cacert ];
          text = ''
            set -euo pipefail

            SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

            exec bwrap \
              --ro-bind /nix /nix \
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
              bash
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            hugo_0_138_0
            go
            pkgs.bubblewrap
            pkgs.bashInteractive
            pkgs.cacert
            pkgs.git
            pkgs.which
            secureRun
          ];
        };
      }
    );
}
