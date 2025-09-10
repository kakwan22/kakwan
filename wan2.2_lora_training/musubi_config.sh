# The file extension is purely so it shows up with nice colors on Jupyter, only god can judge me for making stupid decisions.

# ====== WAN 2.2 AIO LoRA Training Config ======
# LoRA rank drives both network_dim and network_alpha
LORA_RANK=16

# training schedule - shorter for video training
MAX_EPOCHS=40
SAVE_EVERY=20

# seed for AIO LoRA training (low-noise compatible)
SEED_LOW=42

# optimizer
LEARNING_RATE=3e-4

# dataset: "video" or "image"
DATASET_TYPE=video

# resolution list for bucketed training (must be TOML-ish array)
# For 720p videos: 1280x720
RESOLUTION_LIST="1024, 576"

# common dataset paths (adjust if you keep data elsewhere)
DATASET_DIR="/workspace/kakwan/video_dataset_here"

# AIO LoRA Name
TITLE_LOW="WAN22_AIO_LoRA"

# ---- IMAGE options (used only when DATASET_TYPE=image) ----
BATCH_SIZE=1
NUM_REPEATS=1

# ---- VIDEO options (used only when DATASET_TYPE=video) ----
# frames per sample; TOML array (Musubi rounds like [1,57,117])
TARGET_FRAMES="1, 57, 117"
FRAME_EXTRACTION="head"     # head | middle | tail (per wan2.2_lora_training docs)
NUM_REPEATS=1

# Optional caption extension used by both modes
CAPTION_EXT=".txt"

# Set to 1 to skip caching after first run (speeds up subsequent runs)
# IMPORTANT: Keep at 0 for first run to cache both videos AND images for i2v
SKIP_CACHE=0

# Maximum frames per video (300 = ~10 seconds at 30fps)
MAX_FRAMES=300
