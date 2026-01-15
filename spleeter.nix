{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.ffmpeg
    pkgs.libsndfile
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.gcc  # Provides libstdc++.so.6
  ];

  LD_LIBRARY_PATH="${pkgs.gcc.cc.lib}/lib64:$LD_LIBRARY_PATH";

  shellHook = ''
    # Create and activate a virtual environment
    if [ ! -d ".venv" ]; then
      python -m venv .venv
    fi
    source .venv/bin/activate

    # Install Spleeter if not already installed
    if ! pip show spleeter > /dev/null 2>&1; then
      pip install spleeter
    fi
  '';
}
