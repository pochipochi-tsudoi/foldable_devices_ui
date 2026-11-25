#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tool/video_to_gif.sh <input_video> <output_gif> [width] [fps]

Convert an MP4/MOV screen recording into a palette-optimized GIF using ffmpeg.

Arguments:
  input_video  Path to the source video file (.mp4, .mov, etc.)
  output_gif   Destination path for the generated .gif file
  width        Optional output width in pixels, keeping aspect ratio (default: 640)
  fps          Optional frame rate (default: 12)
EOF
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage >&2
  exit 1
fi

INPUT_VIDEO="$1"
OUTPUT_GIF="$2"
WIDTH="${3:-640}"
FPS="${4:-12}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$INPUT_VIDEO" ]]; then
  echo "Error: input file not found: $INPUT_VIDEO" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_GIF")"

PALETTE_BASE="$(mktemp "${TMPDIR:-/tmp}/palette.XXXXXX")"
PALETTE="${PALETTE_BASE}.png"
trap 'rm -f "$PALETTE_BASE" "$PALETTE"' EXIT

FILTERS="fps=${FPS},scale=${WIDTH}:-1:flags=lanczos"

ffmpeg -y -v error \
  -i "$INPUT_VIDEO" \
  -vf "${FILTERS},palettegen=stats_mode=diff" \
  -update 1 \
  "$PALETTE"

ffmpeg -y -v error \
  -i "$INPUT_VIDEO" \
  -i "$PALETTE" \
  -lavfi "${FILTERS}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  -loop 0 \
  "$OUTPUT_GIF"

echo "Generated: $OUTPUT_GIF ($(du -h "$OUTPUT_GIF" | cut -f1))"
