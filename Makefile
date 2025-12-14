# Never the Same - Wind Animation Processor
# Assembles frames into video/GIF at 16fps
#
# Usage:
#   make all           - Create animation (native resolution)
#   make 4k-vertical   - Create 4K vertical (2160x3840) for phone/portrait screens
#   make 4k-horizontal - Create 4K horizontal (3840x2160) for TV/landscape screens
#   make clean         - Remove processed files
#   make help          - Show all options

# Configuration
FRAMES_DIR ?= frames
OUTPUT_DIR ?= renders
FPS ?= 16
SCRIPT = ./process_frames.sh

# Set default target
.DEFAULT_GOAL := default

.PHONY: all 4k-vertical 4k-horizontal clean check info help default

# Default target: Show available targets
default:
	@echo ""
	@echo "  Never the Same - Wind Animation Processor"
	@echo "  ─────────────────────────────────────────"
	@echo ""
	@echo "  make all           Render native resolution (square)"
	@echo "  make 4k-vertical   Render 4K vertical (2160×3840)"
	@echo "  make 4k-horizontal  Render 4K horizontal (3840×2160)"
	@echo ""
	@echo "  make info           Show frame information"
	@echo "  make clean          Remove all outputs"
	@echo ""

# Native resolution (no crop)
all: check
	@chmod +x $(SCRIPT)
	@$(SCRIPT) "$(FRAMES_DIR)" "$(OUTPUT_DIR)" "native"

# 4K Vertical (2160x3840) - for phones, portrait displays
4k-vertical: check
	@chmod +x $(SCRIPT)
	@$(SCRIPT) "$(FRAMES_DIR)" "$(OUTPUT_DIR)" "4k-vertical"

# 4K Horizontal (3840x2160) - for TVs, landscape displays
4k-horizontal: check
	@chmod +x $(SCRIPT)
	@$(SCRIPT) "$(FRAMES_DIR)" "$(OUTPUT_DIR)" "4k-horizontal"

# Check dependencies
check:
	@command -v ffmpeg >/dev/null 2>&1 || { \
		echo "❌ ffmpeg is not installed."; \
		echo "Install with: brew install ffmpeg"; \
		exit 1; \
	}
	@echo "✓ ffmpeg is installed"

# Show frame information
info:
	@echo "═══════════════════════════════════════════════════════════"
	@echo "  Frame Information"
	@echo "═══════════════════════════════════════════════════════════"
	@if [ ! -d "$(FRAMES_DIR)" ]; then \
		echo "Frames directory '$(FRAMES_DIR)/' not found."; \
		echo "Press 'w' in the browser artwork to download frames."; \
	else \
		FRAMES=$$(ls -1 $(FRAMES_DIR)/*.png 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$FRAMES" -eq 0 ]; then \
			echo "No frames found. Press 'w' in browser to download."; \
		else \
			echo "Found $$FRAMES frames"; \
			FIRST=$$(ls -1 $(FRAMES_DIR)/*.png | sort -V | head -1); \
			DIM=$$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$$FIRST" 2>/dev/null); \
			echo "Dimensions: $$DIM"; \
			echo "Duration: $$(echo "scale=2; $$FRAMES / $(FPS)" | bc)s @ $(FPS)fps"; \
		fi; \
	fi
	@echo "═══════════════════════════════════════════════════════════"

# Clean all outputs
clean:
	@rm -rf $(OUTPUT_DIR)
	@echo "✓ Cleaned renders directory"

# Help (same as default)
help: default
