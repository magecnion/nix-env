#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./meshtastic-backup.sh [-o OUTPUT_DIR] [meshtastic connection args...]

Examples:
  ./meshtastic-backup.sh
  ./meshtastic-backup.sh --port /dev/ttyUSB0
  ./meshtastic-backup.sh --host meshtastic.local
  ./meshtastic-backup.sh -o backups/my-node --port /dev/ttyUSB0

This script saves a timestamped Meshtastic backup containing:
  - config.yaml   (`meshtastic --export-config`)
  - info.txt      (`meshtastic --info`)
  - channels.txt  (`meshtastic --qr-all`)
  - nodes.txt     (`meshtastic --nodes`)
  - metadata.txt  (backup metadata and CLI args)

If no connection args are provided, the Meshtastic CLI will use its normal auto-detection behavior.
EOF
}

output_dir="meshtastic-backup-$(date +%Y%m%d-%H%M%S)"
cli_args=()

while (($# > 0)); do
  case "$1" in
    -o|--output-dir)
      if (($# < 2)); then
        echo "Missing value for $1" >&2
        exit 1
      fi
      output_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      cli_args+=("$1")
      shift
      ;;
  esac
done

mkdir -p "$output_dir"

cmd=(meshtastic)
if ((${#cli_args[@]} > 0)); then
  cmd+=("${cli_args[@]}")
fi

printf 'Saving Meshtastic backup to %s\n' "$output_dir"

{
  printf 'created_at=%s\n' "$(date -Iseconds)"
  printf 'working_directory=%s\n' "$PWD"
  printf 'command='
  printf '%q ' "${cmd[@]}"
  printf '\n'
} > "$output_dir/metadata.txt"

"${cmd[@]}" --export-config > "$output_dir/config.yaml"
"${cmd[@]}" --info > "$output_dir/info.txt"
"${cmd[@]}" --qr-all > "$output_dir/channels.txt"
"${cmd[@]}" --nodes > "$output_dir/nodes.txt"

printf 'Backup complete. Files written to %s\n' "$output_dir"
