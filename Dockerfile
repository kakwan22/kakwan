# WAN 2.2 AIO LoRA Training - RunPod Docker Image
FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NETWORK_VOLUME=/workspace
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV PATH="/opt/miniconda/bin:$PATH"

# Install system dependencies in one layer
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    unzip \
    ffmpeg \
    python3-venv \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /workspace

# Copy the entire diffusion_pipe_working_folder
COPY . /workspace/

# Make all shell scripts executable
RUN find /workspace -name "*.sh" -type f -exec chmod +x {} \;

# Create necessary directories
RUN mkdir -p \
    /workspace/video_dataset_here \
    /workspace/image_dataset_here \
    /workspace/wan2.2_lora_training/output \
    /workspace/logs

# Install core Python packages first (most stable)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    huggingface_hub \
    hf_transfer \
    accelerate \
    transformers \
    pillow \
    jupyterlab \
    notebook \
    ipywidgets

# Set up JoyCaption environment (simplified - no conda complications)
WORKDIR /workspace/Captioning/JoyCaption
RUN python3 -m venv joy_caption_env && \
    . joy_caption_env/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    pip install --no-cache-dir transformers accelerate pillow

# Install miniconda (simpler approach)
WORKDIR /tmp
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/miniconda && \
    rm miniconda.sh && \
    /opt/miniconda/bin/conda init bash

# Only clone TripleX if we actually need it (conditional)
RUN if [ ! -d "/TripleX" ]; then \
        git clone https://github.com/Hearmeman24/TripleX.git /TripleX || \
        echo "TripleX repo clone failed - video captioning may not work"; \
    fi

# Create simple conda environment (no complex dependencies)
RUN /bin/bash -c "source /opt/miniconda/etc/profile.d/conda.sh && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda config --set channel_priority flexible && \
    conda create -y -n TripleX python=3.11 && \
    conda activate TripleX && \
    pip install --no-cache-dir torch torchvision && \
    if [ -f '/TripleX/requirements.txt' ]; then \
        pip install --no-cache-dir -r /TripleX/requirements.txt || echo 'TripleX requirements failed'; \
    fi"

# Back to workspace
WORKDIR /workspace

# Create Jupyter Lab configuration
RUN jupyter lab --generate-config && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.token = ''" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> ~/.jupyter/jupyter_lab_config.py

# Create robust startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash
set -e

echo "=== WAN 2.2 AIO LoRA Training Environment ==="
echo "Dataset directories:"
echo "- Videos: /workspace/video_dataset_here/"
echo "- Images: /workspace/image_dataset_here/"
echo ""
echo "Available scripts:"
echo "- ./interactive_start_training.sh (Main training)"
echo "- ./Captioning/JoyCaption/JoyCaptionRunner.sh (Image captioning)"
if [ -d "/TripleX" ]; then
    echo "- ./Captioning/video_captioner.sh (Video captioning - requires GEMINI_API_KEY)"
fi
echo ""

# Check GPU
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "GPU Status:"
    nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader,nounits | head -1
    echo ""
fi

echo "Starting Jupyter Lab on port 8888..."
cd /workspace
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
EOF

RUN chmod +x /start.sh

# Final cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose Jupyter Lab port
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8888/ || exit 1

# Set default command
CMD ["/start.sh"]