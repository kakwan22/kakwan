# WAN 2.2 AIO LoRA Training - RunPod Template

## Quick Setup

### 1. Build & Push Docker Image

```bash
# Build the image
docker build -t your-dockerhub-username/wan22-lora-training:latest .

# Push to Docker Hub
docker push your-dockerhub-username/wan22-lora-training:latest
```

### 2. Deploy on RunPod

1. Go to RunPod Templates
2. Create new template with your Docker image
3. Set ports: `8888:8888` (for Jupyter Lab)
4. Add environment variables:
   - `GEMINI_API_KEY` (for video captioning)
5. Deploy pod

### 3. Usage Workflow

1. **Access Jupyter Lab**: Open port 8888 in browser
2. **Upload data**: Drag videos to `/workspace/video_dataset_here/`
3. **Caption videos**: Run captioning script
4. **Train LoRA**: Execute `./interactive_start_training.sh`

## Available Scripts

- `./interactive_start_training.sh` - Main training interface
- `./Captioning/JoyCaption/JoyCaptionRunner.sh` - Image captioning
- `./Captioning/video_captioner.sh` - Video captioning (needs GEMINI_API_KEY)

## Dataset Structure

```
/workspace/
├── video_dataset_here/     # Upload your videos here
│   ├── video1.mp4
│   ├── video1.txt         # Generated captions
│   └── ...
├── image_dataset_here/     # For image training
└── wan2.2_lora_training/
    └── output/            # Trained LoRAs appear here
```

## Training Configuration

Edit `wan2.2_lora_training/musubi_config.sh` to customize:
- Epochs (default: 100)
- Resolution (default: 1024x1024) 
- LoRA rank (default: 16)
- Dataset type (video/image)

## Expected Training Time

- 20-50 videos: ~2-4 hours on H100
- Saves checkpoints every 20 epochs
- Final output: 5 LoRA files to test