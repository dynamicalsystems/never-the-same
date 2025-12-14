# Never the Same
**Wind Animation Renderer**

Artwork by [Nat Sarkissian](https://verse.works/series/never-the-same-by-nat-sarkissian)

![Wind Animation](assets/wind_animation_small.gif)

Processes animation frames from "Never the Same" into high-quality video and GIF formats optimized for different use cases.

## Quick Start

### 0. Clone this repository

```bash
git clone git@github.com:dynamicalsystems/never-the-same.git
cd never-the-same
```

### 1. Install prerequisites

```bash
brew install ffmpeg
```

### 2. Download Frames

**Wind animation:** Navigate to one of the [outputs from Never the Same](https://verse.works/artworks/512560f0-41f7-40d8-bad5-ea977d7dcee6/61). With the code running in your browser, tap the **'w'** key. This will start a loop that renders and downloads 30 frames. When it's done, you'll have 30 PNG files on your hard drive.

Move the downloaded PNG files to the `frames/` directory in this project.

### 3. Render the Animation

```bash
# Show all available targets
make

# Render all versions (native, 4k-vertical, 4k-horizontal)
make all

# Or render individual formats
make native
make 4k-vertical
make 4k-horizontal
make gif-small
```

## Output Formats

| Command | Resolution | Outputs | Use Case |
|---------|-----------|---------|----------|
| `make all` | All versions | MP4 + GIF for each | Complete set for all platforms |
| `make native` | Native (square) | MP4 + GIF | Original artwork, general use |
| `make 4k-vertical` | 2160×3840 | MP4 + GIF | Phone, portrait displays, Instagram Stories |
| `make 4k-horizontal` | 3840×2160 | MP4 + GIF | TV, landscape displays, presentations |
| `make gif-small` | ~800×800 | GIF only | Web sharing, social media (<15MB) |

## Output Details

All renders are saved to the `renders/` directory with namespaced filenames:

- `wind_animation.mp4` / `wind_animation.gif` — Native resolution
- `wind_animation_4k-vertical.mp4` / `wind_animation_4k-vertical.gif` — 4K vertical
- `wind_animation_4k-horizontal.mp4` / `wind_animation_4k-horizontal.gif` — 4K horizontal
- `wind_animation_small.gif` — Optimized small GIF (<15MB, GIF only)

### File Specifications

- **MP4** — H.264 video, 16fps, high quality (CRF 18)
- **GIF** — Looping GIF, 2x playback speed (matches MP4 timing), optimized palette
- **GIF (small)** — Reduced resolution (~800×800), 128 colors, aggressive compression, auto-scales down if needed

**Note:** GIFs are generated from MP4 files for smoother playback and consistent timing.

## Other Commands

```bash
make          # Show all available targets
make info     # Show frame information (count, dimensions, duration)
make clean    # Remove all outputs from renders/ directory
```

## Technical Details

- **Frame rate**: 16fps (as recommended by the artist)
- **GIF optimization**: Two-pass palette generation for optimal color quality
- **GIF playback**: 2x speed to match MP4 timing
- **Small GIF**: Automatically reduces resolution if file size exceeds 15MB
