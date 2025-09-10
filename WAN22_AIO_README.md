# WAN 2.2 AIO LoRA Training Template

## Overview
This modified template trains **low-noise LoRAs only** that are compatible with the WAN 2.2 AIO (All-In-One) model for video generation.

## Key Features
- ✅ **AIO Compatible**: Trained LoRAs work with Phr00t's WAN 2.2 AIO model
- ✅ **Simplified**: Single GPU, low-noise training only
- ✅ **Clean**: Removed Flux/SDXL/high-noise complexity
- ✅ **Complete**: Includes JoyCaption and video captioning tools

## Quick Start

### 1. Prepare Your Dataset
**For Images:**
```bash
# Place images in:
/workspace/image_dataset_here/

# Run JoyCaption (optional):
cd Captioning/JoyCaption
bash JoyCaptionRunner.sh --trigger-word "your_concept"
```

**For Videos:**
```bash
# Place videos in:
/workspace/video_dataset_here/

# Run video captioning:
cd Captioning
export GEMINI_API_KEY="your_key"
bash video_captioner.sh
```

### 2. Configure Training
Edit `wan2.2_lora_training/musubi_config.sh`:
```bash
# Basic settings
LORA_RANK=16
DATASET_TYPE=video  # or "image"
TITLE_LOW="MyCustom_LoRA"

# Video options (if using videos)
TARGET_FRAMES="1, 57, 117"
RESOLUTION_LIST="1024, 1024"
```

### 3. Start Training
```bash
# Interactive mode (recommended)
bash interactive_start_training.sh

# Or direct training
cd wan2.2_lora_training
bash setup_and_train_musubi.sh
```

## What's Changed from Original

### Removed:
- Flux model training
- SDXL model training  
- WAN high-noise training
- Dual GPU logic
- Complex model selection prompts

### Simplified:
- Single GPU assumed
- Low-noise training only
- Automatic model downloads
- Streamlined workflow

### Kept:
- JoyCaption for images
- Video captioning with Gemini
- All training parameters
- musubi-tuner integration

## Model Downloads
The training script automatically downloads:
- ✅ WAN 2.1 VAE (compatible with WAN 2.2)
- ✅ T5 text encoder
- ✅ WAN 2.2 low-noise DIT model

**Total download**: ~21GB (vs 42GB for dual models)

## Output
Trained LoRAs are saved to:
```
/workspace/wan2.2_lora_training/output/
```

Use these LoRAs with your WAN 2.2 AIO model in ComfyUI by loading them with the LoRALoader node.

## Requirements
- Single GPU with 24GB+ VRAM recommended
- GEMINI_API_KEY for video captioning (if using videos)
- No HuggingFace token required

## Compatibility
- ✅ Works with: Phr00t WAN 2.2 AIO models
- ✅ LoRA strength: 0.5-1.0 typically works well
- ❌ Not compatible with: WAN 2.2 high-noise LoRAs

---
*Modified for AIO compatibility from hearmeman/diffusion-pipe:v7*