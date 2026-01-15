# shell.nix  – Demucs v4 via pip (CPU wheel)
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ffmpeg
    libsndfile
    sox            # optional
    gcc            # libstdc++.so needed by Torch wheels
    # python3Packages.pip
    python311Packages.pip
    python311Packages.soundfile
  ];

  LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib64:$LD_LIBRARY_PATH";

  shellHook = ''
    if [ ! -d .venv ]; then
      echo "🔧 creating venv and installing Demucs…"
      python -m venv .venv
    fi
    source .venv/bin/activate

    if ! pip show demucs >/dev/null 2>&1; then
      pip install --upgrade pip
      pip install "torch==2.2.*+cpu" --index-url https://download.pytorch.org/whl/cpu
      pip install torchaudio --index-url https://download.pytorch.org/whl/cpu
      pip install "demucs>=4,<5"
    fi

    echo "✅ Demucs $(demucs --version) ready – try:"
    echo "   demucs --two-stems=vocals track.wav"
  '';
}
