#!/bin/bash
#
# Wind Animation Frame Processor for "Never the Same" by Nat Sarkissian
# Assembles frames into video/GIF at 16 FPS
#
# Usage: ./process_frames.sh [frames_dir] [output_dir] [mode]
#   frames_dir: directory containing PNG frames (default: "frames")
#   output_dir: directory for processed files (default: "processed")
#   mode: "native" | "4k-vertical" | "4k-horizontal" (default: "native")

set -e

# Configuration
FRAMES_DIR="${1:-frames}"
OUTPUT_DIR="${2:-processed}"
MODE="${3:-native}"
INPUT_PATTERN="*.png"
FPS=16
GIF_FPS=17  # Slightly faster for GIF to compensate for timing quantization

# Output filenames (namespaced by mode)
case "$MODE" in
    "4k-vertical")
        VIDEO_OUTPUT="wind_animation_4k-vertical.mp4"
        GIF_OUTPUT="wind_animation_4k-vertical.gif"
        ;;
    "4k-horizontal")
        VIDEO_OUTPUT="wind_animation_4k-horizontal.mp4"
        GIF_OUTPUT="wind_animation_4k-horizontal.gif"
        ;;
    *)
        VIDEO_OUTPUT="wind_animation.mp4"
        GIF_OUTPUT="wind_animation.gif"
        ;;
esac
PALETTE="palette.png"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Never the Same - Wind Animation Processor @ ${FPS}fps${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Frames directory: ${FRAMES_DIR}/${NC}"
echo -e "${YELLOW}Mode: ${MODE}${NC}"

# Check for ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: ffmpeg is not installed.${NC}"
    echo "Install with: brew install ffmpeg"
    exit 1
fi

# Check frames directory exists
if [ ! -d "$FRAMES_DIR" ]; then
    echo -e "${RED}Error: Frames directory '$FRAMES_DIR' not found.${NC}"
    echo ""
    echo "Create the directory and add your PNG frames:"
    echo "  mkdir $FRAMES_DIR"
    echo "  # Then download frames by pressing 'w' in the browser artwork"
    exit 1
fi

# Find input frames
FRAMES=($(ls -1 "$FRAMES_DIR"/$INPUT_PATTERN 2>/dev/null | sort -V))
FRAME_COUNT=${#FRAMES[@]}

if [ $FRAME_COUNT -eq 0 ]; then
    echo -e "${RED}Error: No frames found in '$FRAMES_DIR/'${NC}"
    echo ""
    echo "Download frames by pressing 'w' in the browser artwork first."
    exit 1
fi

echo -e "${YELLOW}Found ${FRAME_COUNT} frames${NC}"
echo "First frame: ${FRAMES[0]}"
echo "Last frame: ${FRAMES[$((FRAME_COUNT-1))]}"

# Get dimensions of first frame
FIRST_FRAME="${FRAMES[0]}"
DIMENSIONS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$FIRST_FRAME")
ORIG_W=$(echo $DIMENSIONS | cut -d',' -f1)
ORIG_H=$(echo $DIMENSIONS | cut -d',' -f2)

echo "Original dimensions: ${ORIG_W}x${ORIG_H}"

# Build video filter based on mode
case "$MODE" in
    "4k-vertical")
        # 4K vertical (9:16): Scale to 3840x3840, crop to 2160x3840
        FINAL_W=2160
        FINAL_H=3840
        VIDEO_FILTER="scale=3840:3840:flags=lanczos,crop=${FINAL_W}:${FINAL_H}:(in_w-${FINAL_W})/2:(in_h-${FINAL_H})/2"
        echo "4K Vertical: Scale to 3840x3840, crop to ${FINAL_W}x${FINAL_H}"
        ;;
    "4k-horizontal")
        # 4K horizontal (16:9): Scale to 3840x3840, crop to 3840x2160
        FINAL_W=3840
        FINAL_H=2160
        VIDEO_FILTER="scale=3840:3840:flags=lanczos,crop=${FINAL_W}:${FINAL_H}:(in_w-${FINAL_W})/2:(in_h-${FINAL_H})/2"
        echo "4K Horizontal: Scale to 3840x3840, crop to ${FINAL_W}x${FINAL_H}"
        ;;
    *)
        # Native: No scaling or cropping, preserve original
        FINAL_W=$ORIG_W
        FINAL_H=$ORIG_H
        VIDEO_FILTER=""
        echo "Native: Preserving original ${FINAL_W}x${FINAL_H}"
        ;;
esac

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo ""
echo -e "${YELLOW}Output directory: ${OUTPUT_DIR}/${NC}"
echo -e "${YELLOW}Output resolution: ${FINAL_W}x${FINAL_H}${NC}"

# Detect input pattern for ffmpeg
FIRST_NAME=$(basename "${FRAMES[0]}" .png)
if [[ "$FIRST_NAME" =~ ^(.*[^0-9])([0-9]+)$ ]]; then
    PREFIX="${BASH_REMATCH[1]}"
    NUM="${BASH_REMATCH[2]}"
    NUM_LEN=${#NUM}
    START_NUM=$((10#$NUM))
    FFMPEG_PATTERN="${FRAMES_DIR}/${PREFIX}%0${NUM_LEN}d.png"
    echo "Detected frame pattern: $FFMPEG_PATTERN (starting at $START_NUM)"
elif [[ "$FIRST_NAME" =~ ^([0-9]+)$ ]]; then
    PREFIX=""
    NUM="${BASH_REMATCH[1]}"
    NUM_LEN=${#NUM}
    START_NUM=$((10#$NUM))
    FFMPEG_PATTERN="${FRAMES_DIR}/%0${NUM_LEN}d.png"
    echo "Detected frame pattern: $FFMPEG_PATTERN (starting at $START_NUM)"
else
    echo "Using file list mode for irregular naming"
    FFMPEG_PATTERN=""
fi

echo ""

# Build filter string (empty for native mode)
if [ -n "$VIDEO_FILTER" ]; then
    VF_ARG="-vf $VIDEO_FILTER"
    VF_PALETTE="${VIDEO_FILTER},palettegen=stats_mode=full"
    VF_GIF="${VIDEO_FILTER}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5"
else
    VF_ARG=""
    VF_PALETTE="palettegen=stats_mode=full"
    VF_GIF="[0:v][1:v]paletteuse=dither=bayer:bayer_scale=5"
fi

# ═══════════════════════════════════════════════════════════
# Create MP4 Video
# ═══════════════════════════════════════════════════════════
echo -e "${GREEN}Creating MP4 video...${NC}"

if [ -n "$FFMPEG_PATTERN" ]; then
    if [ -n "$VIDEO_FILTER" ]; then
        ffmpeg -y -framerate $FPS -start_number $START_NUM -i "$FFMPEG_PATTERN" \
            -vf "$VIDEO_FILTER" \
            -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
            -movflags +faststart \
            "$OUTPUT_DIR/$VIDEO_OUTPUT" \
            2>&1 | grep -E "(frame|fps|time|bitrate|speed)" || true
    else
        ffmpeg -y -framerate $FPS -start_number $START_NUM -i "$FFMPEG_PATTERN" \
            -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
            -movflags +faststart \
            "$OUTPUT_DIR/$VIDEO_OUTPUT" \
            2>&1 | grep -E "(frame|fps|time|bitrate|speed)" || true
    fi
else
    FILELIST="$OUTPUT_DIR/filelist.txt"
    > "$FILELIST"
    for f in "${FRAMES[@]}"; do
        echo "file '$(pwd)/$f'" >> "$FILELIST"
        echo "duration $(echo "scale=6; 1/$FPS" | bc)" >> "$FILELIST"
    done
    
    if [ -n "$VIDEO_FILTER" ]; then
        ffmpeg -y -f concat -safe 0 -i "$FILELIST" \
            -vf "$VIDEO_FILTER" \
            -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
            -movflags +faststart \
            "$OUTPUT_DIR/$VIDEO_OUTPUT" \
            2>&1 | grep -E "(frame|fps|time|bitrate|speed)" || true
    else
        ffmpeg -y -f concat -safe 0 -i "$FILELIST" \
            -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
            -movflags +faststart \
            "$OUTPUT_DIR/$VIDEO_OUTPUT" \
            2>&1 | grep -E "(frame|fps|time|bitrate|speed)" || true
    fi
    
    rm "$FILELIST"
fi

echo -e "${GREEN}✓ Created: ${OUTPUT_DIR}/${VIDEO_OUTPUT}${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# Create Looping GIF (two-pass for quality)
# ═══════════════════════════════════════════════════════════
echo -e "${GREEN}Creating looping GIF (two-pass for quality)...${NC}"

# Pass 1: Generate optimized palette
echo "  Pass 1: Generating color palette..."
if [ -n "$FFMPEG_PATTERN" ]; then
    ffmpeg -y -framerate $FPS -start_number $START_NUM -i "$FFMPEG_PATTERN" \
        -vf "$VF_PALETTE" \
        "$OUTPUT_DIR/$PALETTE" \
        2>&1 | grep -E "(frame|fps)" || true
else
    FILELIST="$OUTPUT_DIR/filelist.txt"
    > "$FILELIST"
    for f in "${FRAMES[@]}"; do
        echo "file '$(pwd)/$f'" >> "$FILELIST"
        echo "duration $(echo "scale=6; 1/$FPS" | bc)" >> "$FILELIST"
    done
    
    ffmpeg -y -f concat -safe 0 -i "$FILELIST" \
        -vf "$VF_PALETTE" \
        "$OUTPUT_DIR/$PALETTE" \
        2>&1 | grep -E "(frame|fps)" || true
fi

# Pass 2: Create GIF using palette (use faster framerate for better timing)
# GIF timing is quantized to centiseconds, so 17fps (58.8ms) maps better than 16fps (62.5ms)
echo "  Pass 2: Creating GIF with palette..."
if [ -n "$FFMPEG_PATTERN" ]; then
    ffmpeg -y -framerate $FPS -start_number $START_NUM -i "$FFMPEG_PATTERN" \
        -i "$OUTPUT_DIR/$PALETTE" \
        -lavfi "$VF_GIF" \
        -r $GIF_FPS \
        -loop 0 \
        "$OUTPUT_DIR/$GIF_OUTPUT" \
        2>&1 | grep -E "(frame|fps)" || true
else
    ffmpeg -y -f concat -safe 0 -i "$FILELIST" \
        -i "$OUTPUT_DIR/$PALETTE" \
        -lavfi "$VF_GIF" \
        -r $GIF_FPS \
        -loop 0 \
        "$OUTPUT_DIR/$GIF_OUTPUT" \
        2>&1 | grep -E "(frame|fps)" || true
    
    rm "$FILELIST"
fi

# Clean up palette
rm -f "$OUTPUT_DIR/$PALETTE"

echo -e "${GREEN}✓ Created: ${OUTPUT_DIR}/${GIF_OUTPUT}${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Processing Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Output files:"
ls -lh "$OUTPUT_DIR/$VIDEO_OUTPUT" "$OUTPUT_DIR/$GIF_OUTPUT" 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Duration: $(echo "scale=2; $FRAME_COUNT / $FPS" | bc) seconds @ ${FPS}fps"
echo ""
