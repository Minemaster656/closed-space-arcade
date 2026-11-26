#!/usr/bin/env bash
# Generates white/alpha placeholder FX atlases. They are meant to be tinted
# in-engine and later replaced by hand-drawn art with the same frame layout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/sprites/fx"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$OUT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
montage_atlas() {
    local out="$1"
    local tile="$2"
    shift 2
    magick montage "$@" -tile "$tile" -geometry +0+0 -background none "$out"
}

# 16x16 spark frames: a bright dot with a short trail, rotated in 22.5° steps.
make_spark_frames() {
    magick -size 16x16 xc:none \
        -stroke white -strokewidth 1 -fill white \
        -draw "line 8,8 8,2" \
        -draw "circle 8,8 8,6" \
        "$TMP/spark_base.png"
    for i in $(seq 0 15); do
        local angle=$((i * 23))
        magick "$TMP/spark_base.png" -background none -filter point \
            -rotate "$angle" -gravity center -crop 16x16+0+0 +repage \
            "$TMP/spark_$i.png"
    done
    montage_atlas "$OUT/atlas_spark.png" 4x4 "$TMP"/spark_[0-9]*.png
}

# 16x16 flash frames: four-point starburst, rotated and scaled a little.
make_flash_frames() {
    magick -size 16x16 xc:none -fill white \
        -draw "polygon 8,0 10,6 16,8 10,10 8,16 6,10 0,8 6,6" \
        "$TMP/flash_base.png"
    for i in $(seq 0 15); do
        local angle=$((i * 23))
        local scale=$((90 + (i % 4) * 5))
        magick "$TMP/flash_base.png" -background none -filter point \
            -rotate "$angle" -gravity center -crop 16x16+0+0 +repage \
            -resize "${scale}%" -gravity center -extent 16x16 \
            "$TMP/flash_$i.png"
    done
    montage_atlas "$OUT/atlas_flash.png" 4x4 "$TMP"/flash_[0-9]*.png
}

# 16x16 muzzle frames: a cone/star pointing up, rotated for variety.
make_muzzle_frames() {
    magick -size 16x16 xc:none -fill white \
        -draw "polygon 8,0 11,7 16,8 11,9 8,16 5,9 0,8 5,7" \
        -draw "circle 8,8 8,5" \
        "$TMP/muzzle_base.png"
    for i in $(seq 0 15); do
        local angle=$((i * 23))
        magick "$TMP/muzzle_base.png" -background none -filter point \
            -rotate "$angle" -gravity center -crop 16x16+0+0 +repage \
            "$TMP/muzzle_$i.png"
    done
    montage_atlas "$OUT/atlas_muzzle.png" 4x4 "$TMP"/muzzle_[0-9]*.png
}

# 16x16 pickup frames: diamond/sparkle shapes.
make_pickup_frames() {
    magick -size 16x16 xc:none -fill white \
        -draw "polygon 8,0 10,6 16,8 10,10 8,16 6,10 0,8 6,6" \
        -draw "circle 8,8 8,5" \
        "$TMP/pickup_base.png"
    for i in $(seq 0 15); do
        local angle=$((i * 23))
        local scale=$((80 + (i % 5) * 5))
        magick "$TMP/pickup_base.png" -background none -filter point \
            -rotate "$angle" -gravity center -crop 16x16+0+0 +repage \
            -resize "${scale}%" -gravity center -extent 16x16 \
            "$TMP/pickup_$i.png"
    done
    montage_atlas "$OUT/atlas_pickup.png" 4x4 "$TMP"/pickup_[0-9]*.png
}

# 16x16 debris frames: chunky polygons with a couple of rotations.
make_debris_frames() {
    local prefix="$1"
    local shapes=(
        "3,4 8,2 13,5 12,11 7,14 2,10"
        "2,6 7,3 14,6 13,12 6,13"
        "4,2 12,3 14,9 9,14 3,11 2,7"
        "2,5 6,2 12,4 14,10 10,14 4,12 3,8"
    )
    local n=0
    for shape in "${shapes[@]}"; do
        for angle in 0 23 47 71; do
            magick -size 16x16 xc:none -fill white -stroke white -strokewidth 1 \
                -draw "polygon $shape" \
                "$TMP/${prefix}_base.png"
            magick "$TMP/${prefix}_base.png" -background none -filter point \
                -rotate "$angle" -gravity center -crop 16x16+0+0 +repage \
                "$TMP/${prefix}_$n.png"
            n=$((n + 1))
        done
    done
    montage_atlas "$OUT/atlas_debris_${prefix}.png" 4x4 "$TMP/${prefix}"_[0-9]*.png
}

# 32x32 soft smoke puffs, four variants.
make_smoke_frames() {
    for i in $(seq 0 15); do
        local radius=$((4 + (i % 4)))
        local blur=$((2 + (i % 3)))
        magick -size 32x32 xc:none -fill white \
            -draw "circle 16,16 16,$radius" \
            -blur "0x$blur" \
            "$TMP/smoke_$i.png"
    done
    montage_atlas "$OUT/atlas_smoke.png" 4x4 "$TMP"/smoke_[0-9]*.png
}

# 64x64 ring frames, 2x2 atlas.
make_ring_frames() {
    magick -size 64x64 xc:none -stroke white -strokewidth 4 -fill none \
        -draw "circle 32,32 32,3" "$TMP/ring_0.png"
    magick -size 64x64 xc:none -stroke white -strokewidth 3 -fill none \
        -draw "arc 4,4 60,60 20,160" \
        -draw "arc 4,4 60,60 200,340" "$TMP/ring_1.png"
    magick -size 64x64 xc:none -stroke white -strokewidth 2 -fill none \
        -draw "circle 32,32 32,6" \
        -draw "circle 32,32 32,12" "$TMP/ring_2.png"
    magick -size 64x64 xc:none -stroke white -strokewidth 6 -fill none \
        -draw "circle 32,32 32,4" -blur 0x2 "$TMP/ring_3.png"
    montage_atlas "$OUT/atlas_ring.png" 2x2 "$TMP"/ring_[0-9]*.png
}

make_spark_frames
make_flash_frames
make_muzzle_frames
make_pickup_frames
make_debris_frames rock
make_debris_frames ice
make_debris_frames metal
make_smoke_frames
make_ring_frames

echo "Generated FX atlases in $OUT"
identify "$OUT"/atlas_*.png
