#!/usr/bin/env bash
# Generates silent WAV placeholders for the keyed SFX library.
# Replace them with real recordings later; the filenames and keys stay the same.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/sounds/sfx"
mkdir -p "$OUT"

# key:base_duration_seconds
KEYS=(
    "shoot:0.040"
    "hit_rock:0.040"
    "hit_ice:0.050"
    "hit_metal:0.040"
    "break_rock:0.080"
    "break_ice:0.080"
    "explosion_enemy:0.120"
    "explosion_player:0.160"
    "pickup_shard:0.050"
    "pickup_comet:0.080"
)

for entry in "${KEYS[@]}"; do
    key="${entry%%:*}"
    base="${entry##*:}"
    for i in 1 2 3; do
        # Slightly different lengths make it obvious that variations are wired.
        duration="$(awk -v b="$base" -v i="$i" 'BEGIN { printf "%.3f", b + (i - 1) * 0.005 }')"
        sox -n -r 44100 -c 1 -b 16 "$OUT/${key}_0${i}.wav" trim 0 "$duration"
    done
done

echo "Generated placeholder SFX in $OUT"
ls -1 "$OUT"
