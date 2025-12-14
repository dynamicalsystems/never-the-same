# Never the Same #61
**Wind Animation Renderer**

Artwork by [Nat Sarkissian](https://verse.works/series/never-the-same-by-nat-sarkissian)

## Quick Start

### 0. Clone this repository

### 1. Install prerequisites
```bash
brew install ffmpeg
```

### 2. Download Frames

**Wind animation:** Navigate to one of the [outputs from Never the Same](https://verse.works/artworks/512560f0-41f7-40d8-bad5-ea977d7dcee6/61). With the code running in your browser, you can tap the **'w'** key. This will start a loop that renders and downloads 30 frames. When it's done, you'll have 30 PNG files on your hard drive.

Move the downloaded PNG files to the `frames/` directory in this project.

### 3. Render the Animation

```bash
# Show all available targets
make

# Render native resolution (square)
make all
```

## Output Formats

| Command | Resolution | Use Case |
|---------|------------|----------|
| `make all` | Native (square) | Original artwork |
| `make 4k-vertical` | 2160×3840 | Phone, portrait displays |
| `make 4k-horizontal` | 3840×2160 | TV, landscape displays |

## Output

All renders are saved to the `renders/` directory with namespaced filenames:

- `wind_animation.mp4` / `wind_animation.gif` — Native resolution
- `wind_animation_4k-vertical.mp4` / `wind_animation_4k-vertical.gif` — 4K vertical
- `wind_animation_4k-horizontal.mp4` / `wind_animation_4k-horizontal.gif` — 4K horizontal

Each render creates:
- **MP4** — H.264 video (best quality, 16fps)
- **GIF** — Looping GIF (17fps, optimized for web)

## Other Commands

```bash
make          # Show all available targets
make info     # Show frame information
make clean    # Remove all outputs
```
