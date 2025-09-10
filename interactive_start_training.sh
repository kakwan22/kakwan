#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Colors for better UX - compatible with both light and dark terminals
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${CYAN}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Welcome message
clear
print_header "Welcome to HearmemanAI LoRA Trainer using Diffusion Pipe"
echo ""
echo -e "${PURPLE}This interactive script will guide you through setting up and starting a LoRA training session.${NC}"
echo -e "${RED}Before you start, make sure to add your datasets to their respective folders.${NC}"
echo ""

# Create logs directory
mkdir -p "/workspace/kakwan/logs"

# Simplified model selection for AIO LoRA training
echo -e "${BOLD}WAN 2.2 AIO LoRA Training Options:${NC}"
echo ""
echo "1) WAN 2.2 14B Text-To-Video (Supports both T2V and I2V)"
echo "2) WAN 2.2 14B Image-To-Video (Advanced users only)"
echo ""

while true; do
    read -p "Enter your choice (1-2): " model_choice
    case $model_choice in
        1)
            MODEL_TYPE="wan22_t2v"
            MODEL_NAME="WAN 2.2 14B Text-To-Video (AIO Compatible)"
            break
            ;;
        2)
            MODEL_TYPE="wan22_i2v"
            MODEL_NAME="WAN 2.2 14B Image-To-Video (AIO Compatible)"
            break
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

echo ""
print_success "Selected model: $MODEL_NAME"
echo ""

# API keys for WAN 2.2 training (only GEMINI needed for video captioning)
# HuggingFace token not required for WAN 2.2 training

echo ""

# Dataset selection
print_header "Dataset Configuration"
echo ""
echo -e "${BOLD}Do you want to caption images and/or videos?${NC}"
echo ""
echo "1) Images only"
echo "2) Videos only"
echo "3) Both images and videos"
echo "4) Skip captioning (use existing captions)"
echo ""

while true; do
    read -p "Enter your choice (1-4): " caption_choice
    case $caption_choice in
        1)
            CAPTION_MODE="images"
            break
            ;;
        2)
            CAPTION_MODE="videos"
            break
            ;;
        3)
            CAPTION_MODE="both"
            break
            ;;
        4)
            CAPTION_MODE="skip"
            break
            ;;
        *)
            print_error "Invalid choice. Please enter a number between 1-4."
            ;;
    esac
done

echo ""

# Check dataset directories
if [ "$CAPTION_MODE" != "skip" ]; then
    IMAGE_DIR="/workspace/kakwan/image_dataset_here"
    VIDEO_DIR="/workspace/kakwan/video_dataset_here"

    # Check Gemini API key if video captioning is needed
    if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
        if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "token_here" ]; then
            print_warning "Gemini API key is required for video captioning."
            echo ""
            echo "You can get your API key from: https://aistudio.google.com/app/apikey"
            echo ""
            read -p "Please enter your Gemini API key: " gemini_key
            if [ -z "$gemini_key" ]; then
                print_error "API key cannot be empty. Exiting."
                exit 1
            fi
            export GEMINI_API_KEY="$gemini_key"
            print_success "Gemini API key set successfully."
        else
            print_success "Gemini API key already set."
        fi
        echo ""
    fi

    # Ask for trigger word if image captioning is needed
    TRIGGER_WORD=""
    if [ "$CAPTION_MODE" = "images" ] || [ "$CAPTION_MODE" = "both" ]; then
        echo -e "${BOLD}Image Captioning Configuration:${NC}"
        echo ""
        read -p "Enter a trigger word for image captions (or press Enter for none): " TRIGGER_WORD
        if [ -n "$TRIGGER_WORD" ]; then
            print_success "Trigger word set: '$TRIGGER_WORD'"
        else
            print_info "No trigger word set"
        fi
        echo ""
    fi

    # Function to check if directory has files
    check_directory() {
        local dir=$1
        local type=$2

        if [ ! -d "$dir" ]; then
            print_error "$type directory does not exist: $dir"
            return 1
        fi

        # Check for files (not just directories)
        if [ "$type" = "Image" ]; then
            file_count=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.gif" -o -iname "*.tiff" -o -iname "*.webp" \) | wc -l)
        else
            file_count=$(find "$dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.webm" \) | wc -l)
        fi

        if [ "$file_count" -eq 0 ]; then
            print_error "No $type files found in: $dir"
            return 1
        fi

        print_success "Found $file_count $type file(s) in: $dir"
        return 0
    }

    # Check based on caption mode
    case $CAPTION_MODE in
        "images")
            if ! check_directory "$IMAGE_DIR" "Image"; then
                echo ""
                print_error "Please add images to $IMAGE_DIR and re-run this script."
                exit 1
            fi
            ;;
        "videos")
            if ! check_directory "$VIDEO_DIR" "Video"; then
                echo ""
                print_error "Please add videos to $VIDEO_DIR and re-run this script."
                exit 1
            fi
            ;;
        "both")
            images_ok=true
            videos_ok=true

            if ! check_directory "$IMAGE_DIR" "Image"; then
                images_ok=false
            fi

            if ! check_directory "$VIDEO_DIR" "Video"; then
                videos_ok=false
            fi

            if [ "$images_ok" = false ] || [ "$videos_ok" = false ]; then
                echo ""
                print_error "Please add the missing files and re-run this script."
                if [ "$images_ok" = false ]; then
                    echo "  - Add images to: $IMAGE_DIR"
                fi
                if [ "$videos_ok" = false ]; then
                    echo "  - Add videos to: $VIDEO_DIR"
                fi
                exit 1
            fi
            ;;
    esac
fi

echo ""
print_success "Dataset validation completed successfully!"
echo ""

# Summary
print_header "Training Configuration Summary"
echo ""
echo -e "${WHITE}Model:${NC} $MODEL_NAME"
echo -e "${WHITE}TOML Config:${NC} $TOML_FILE"
echo -e "${WHITE}Caption Mode:${NC} $CAPTION_MODE"

if [ "$MODEL_TYPE" = "flux" ]; then
    echo -e "${WHITE}Hugging Face Token:${NC} Set ✓"
fi

if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
    echo -e "${WHITE}Gemini API Key:${NC} Set ✓"
fi

echo ""
print_info "Configuration completed! Starting model download and setup..."
echo ""

# WAN 2.2 AIO LoRA setup
print_info "Configuration completed! WAN 2.2 model downloads will be handled during training setup."
echo ""

print_header "WAN 2.2 AIO Training Setup"
echo ""

case $MODEL_TYPE in
    "wan22_t2v")
        print_info "Selected: WAN 2.2 14B Text-to-Video LoRA training (AIO compatible)"
        TRAINING_TASK="t2v-A14B"
        ;;
    "wan22_i2v")
        print_info "Selected: WAN 2.2 14B Image-to-Video LoRA training (AIO compatible)"
        TRAINING_TASK="i2v-A14B"
        ;;
    *)
        print_error "Invalid model type. This should not happen."
        exit 1
        ;;
esac

print_success "Training task set: $TRAINING_TASK"

echo ""

# Start captioning processes if needed
if [ "$CAPTION_MODE" != "skip" ]; then
    print_header "Starting Captioning Process"
    echo ""

    # Clear any existing subfolders in dataset directories before captioning
    if [ "$CAPTION_MODE" = "images" ] || [ "$CAPTION_MODE" = "both" ]; then
        print_info "Cleaning up image dataset directory..."
        # Remove any subdirectories but keep files
        find "/workspace/kakwan/image_dataset_here" -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
        print_success "Image dataset directory cleaned"
    fi

    if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
        print_info "Cleaning up video dataset directory..."
        # Remove any subdirectories but keep files
        find "/workspace/kakwan/video_dataset_here" -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
        print_success "Video dataset directory cleaned"
    fi

    echo ""

    # Start image captioning in background if needed
    if [ "$CAPTION_MODE" = "images" ] || [ "$CAPTION_MODE" = "both" ]; then
        print_info "Starting image captioning process..."
        JOY_CAPTION_SCRIPT="/workspace/kakwan/Captioning/JoyCaption/JoyCaptionRunner.sh"

        if [ -f "$JOY_CAPTION_SCRIPT" ]; then
            if [ -n "$TRIGGER_WORD" ]; then
                bash "$JOY_CAPTION_SCRIPT" --trigger-word "$TRIGGER_WORD" > "/workspace/kakwan/logs/image_captioning.log" 2>&1 &
            else
                bash "$JOY_CAPTION_SCRIPT" > "/workspace/kakwan/logs/image_captioning.log" 2>&1 &
            fi
            IMAGE_CAPTION_PID=$!
            print_success "Image captioning started in background (PID: $IMAGE_CAPTION_PID)"

            # Wait for image captioning with progress indicator
            print_info "Waiting for image captioning to complete..."
            while kill -0 "$IMAGE_CAPTION_PID" 2>/dev/null; do
                if tail -n 1 "/workspace/kakwan/logs/image_captioning.log" 2>/dev/null | grep -q "All done!"; then
                    break
                fi
                echo -n "."
                sleep 2
            done
            echo ""
            print_success "Image captioning completed!"
        else
            print_error "JoyCaption script not found at: $JOY_CAPTION_SCRIPT"
            exit 1
        fi
    fi

    # Start video captioning if needed
    if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
        print_info "Starting video captioning process..."
        VIDEO_CAPTION_SCRIPT="/workspace/kakwan/Captioning/video_captioner.sh"

        if [ -f "$VIDEO_CAPTION_SCRIPT" ]; then
            bash "$VIDEO_CAPTION_SCRIPT" > "/workspace/kakwan/logs/video_captioning.log" 2>&1 &
            VIDEO_CAPTION_PID=$!

            # Wait for video captioning with progress indicator
            print_info "Waiting for video captioning to complete..."
            while kill -0 "$VIDEO_CAPTION_PID" 2>/dev/null; do
                if tail -n 1 "/workspace/kakwan/logs/video_captioning.log" 2>/dev/null | grep -q "video captioning complete"; then
                    break
                fi
                echo -n "."
                sleep 2
            done
            echo ""

            wait "$VIDEO_CAPTION_PID"
            if [ $? -eq 0 ]; then
                print_success "Video captioning completed successfully"
            else
                print_error "Video captioning failed"
                exit 1
            fi
        else
            print_error "Video captioning script not found at: $VIDEO_CAPTION_SCRIPT"
            exit 1
        fi
    fi

    echo ""
fi

# Wait for model download to complete
if [ -n "$MODEL_DOWNLOAD_PID" ]; then
    print_header "Finalizing Model Download"
    echo ""
    print_info "Waiting for model download to complete..."
    while kill -0 "$MODEL_DOWNLOAD_PID" 2>/dev/null; do
        echo -n "."
        sleep 3
    done
    echo ""
    wait "$MODEL_DOWNLOAD_PID"
    print_success "Model download completed!"
    echo ""
fi

# Update dataset.toml file with actual paths and video config
print_header "Configuring Dataset"
echo ""

DATASET_TOML="/workspace/kakwan/diffusion_pipe/examples/dataset.toml"

if [ -f "$DATASET_TOML" ]; then
    print_info "Updating dataset.toml with actual paths..."

    # Create backup
    cp "$DATASET_TOML" "$DATASET_TOML.backup"

    # Replace $NETWORK_VOLUME with actual path in image directory
    sed -i "s|\$NETWORK_VOLUME/image_dataset_here|/workspace/kakwan/image_dataset_here|g" "$DATASET_TOML"

    # Replace $NETWORK_VOLUME with actual path in video directory (even if commented)
    sed -i "s|\$NETWORK_VOLUME/video_dataset_here|/workspace/kakwan/video_dataset_here|g" "$DATASET_TOML"

    # Uncomment video dataset section if user wants to caption videos
    if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
        print_info "Enabling video dataset in configuration..."
        # Uncomment the video directory section
        sed -i '/# \[\[directory\]\]/,/# num_repeats = 5/ s/^# //' "$DATASET_TOML"
    fi

    print_success "Dataset configuration updated"
else
    print_warning "dataset.toml not found at $DATASET_TOML"
fi

# Extract and display training configuration summary
print_header "Training Configuration Summary"
echo ""

# Read resolution from dataset.toml
if [ -f "$DATASET_TOML" ]; then
    RESOLUTION=$(grep "^resolutions = " "$DATASET_TOML" | sed 's/resolutions = \[\([0-9]*\)\]/\1/')
    if [ -z "$RESOLUTION" ]; then
        RESOLUTION="1024 (default)"
    fi
else
    RESOLUTION="1024 (default)"
fi

# Read training parameters from model TOML file
MODEL_TOML="/workspace/kakwan/diffusion_pipe/examples/$TOML_FILE"
if [ -f "$MODEL_TOML" ]; then
    EPOCHS=$(grep "^epochs = " "$MODEL_TOML" | sed 's/epochs = //')
    SAVE_EVERY=$(grep "^save_every_n_epochs = " "$MODEL_TOML" | sed 's/save_every_n_epochs = //')
    RANK=$(grep "^rank = " "$MODEL_TOML" | sed 's/rank = //')
    LR=$(grep "^lr = " "$MODEL_TOML" | sed 's/lr = //')
    OPTIMIZER_TYPE=$(grep "^type = " "$MODEL_TOML" | grep -A5 "\[optimizer\]" | grep "^type = " | sed "s/type = '//;s/'//")

    # Set defaults if not found
    [ -z "$EPOCHS" ] && EPOCHS="1000 (default)"
    [ -z "$SAVE_EVERY" ] && SAVE_EVERY="2 (default)"
    [ -z "$RANK" ] && RANK="32 (default)"
    [ -z "$LR" ] && LR="2e-5 (default)"
    [ -z "$OPTIMIZER_TYPE" ] && OPTIMIZER_TYPE="adamw_optimi (default)"
else
    # Fallback defaults if TOML file not found
    EPOCHS="1000 (default)"
    SAVE_EVERY="2 (default)"
    RANK="32 (default)"
    LR="2e-5 (default)"
    OPTIMIZER_TYPE="adamw_optimi (default)"
fi

echo -e "${BOLD}Model:${NC} $MODEL_NAME"
echo -e "${BOLD}TOML Config:${NC} examples/$TOML_FILE"
echo -e "${BOLD}Resolution:${NC} ${RESOLUTION}"
echo ""

echo -e "${BOLD}Training Parameters:${NC}"
echo "  📊 Epochs: $EPOCHS"
echo "  💾 Save Every: $SAVE_EVERY epochs"
echo "  🎛️  LoRA Rank: $RANK"
echo "  📈 Learning Rate: $LR"
echo "  ⚙️  Optimizer: $OPTIMIZER_TYPE"
echo ""

# Show dataset paths and repeats
if [ "$CAPTION_MODE" != "skip" ]; then
    echo -e "${BOLD}Dataset Configuration:${NC}"

    # Always show image dataset info
    if [ "$CAPTION_MODE" = "images" ] || [ "$CAPTION_MODE" = "both" ]; then
        IMAGE_COUNT=$(find "/workspace/kakwan/image_dataset_here" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.gif" -o -iname "*.tiff" -o -iname "*.webp" \) | wc -l)
        echo "  📷 Images: /workspace/kakwan/image_dataset_here ($IMAGE_COUNT files)"
        echo "     Repeats: 1 per epoch"
    fi

    # Show video dataset info if applicable
    if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
        VIDEO_COUNT=$(find "/workspace/kakwan/video_dataset_here" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.webm" \) | wc -l)
        echo "  🎬 Videos: /workspace/kakwan/video_dataset_here ($VIDEO_COUNT files)"
        echo "     Repeats: 5 per epoch"
    fi
else
    echo -e "${BOLD}Dataset:${NC} Using existing captions"
fi

if [ "$MODEL_TYPE" = "flux" ]; then
    echo -e "${BOLD}Hugging Face Token:${NC} Set ✓"
fi

if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
    echo -e "${BOLD}Gemini API Key:${NC} Set ✓"
fi

echo ""

# Prompt user about configuration files
print_header "Training Configuration"
echo ""

print_info "Before starting training, you can modify the default training parameters in these files:"
echo ""
echo -e "${BOLD}1. Model Configuration:${NC}"
echo "   /workspace/kakwan/diffusion_pipe/examples/$TOML_FILE"
echo ""
echo -e "${BOLD}2. Dataset Configuration:${NC}"
echo "   /workspace/kakwan/diffusion_pipe/examples/dataset.toml"
echo ""

print_warning "These files contain important settings like:"
echo "  • Learning rate, batch size, epochs"
echo "  • Dataset paths and image/video resolutions"
echo "  • LoRA rank and other adapter settings"
echo ""

echo -e "${YELLOW}Would you like to modify these files before starting training?${NC}"
echo "1) Continue with default settings"
echo "2) Pause here - I'll modify the files manually"
echo ""

while true; do
    read -p "Enter your choice (1-2): " config_choice
    case $config_choice in
        1)
            print_success "Continuing with default training settings..."
            break
            ;;
        2)
            print_info "Training paused for manual configuration."
            echo ""
            echo -e "${BOLD}Configuration Files:${NC}"
            echo "1. Model settings: /workspace/kakwan/diffusion_pipe/examples/$TOML_FILE"
            echo "2. Dataset settings: /workspace/kakwan/diffusion_pipe/examples/dataset.toml"
            echo ""
            print_warning "Please modify these files as needed, then return here to continue."
            echo ""

            while true; do
                read -p "Have you finished configuring the settings? (yes/no): " config_done
                case $config_done in
                    yes|YES|y|Y)
                        print_success "Configuration completed. Reading updated settings..."
                        echo ""

                        # Re-read training parameters from updated TOML files
                        MODEL_TOML="/workspace/kakwan/diffusion_pipe/examples/$TOML_FILE"
                        DATASET_TOML="/workspace/kakwan/diffusion_pipe/examples/dataset.toml"

                        # Read resolution from dataset.toml
                        if [ -f "$DATASET_TOML" ]; then
                            RESOLUTION=$(grep "^resolutions = " "$DATASET_TOML" | sed 's/resolutions = \[\([0-9]*\)\]/\1/')
                            if [ -z "$RESOLUTION" ]; then
                                RESOLUTION="1024 (default)"
                            fi
                        else
                            RESOLUTION="1024 (default)"
                        fi

                        # Read training parameters from model TOML file
                        if [ -f "$MODEL_TOML" ]; then
                            EPOCHS=$(grep "^epochs = " "$MODEL_TOML" | sed 's/epochs = //')
                            SAVE_EVERY=$(grep "^save_every_n_epochs = " "$MODEL_TOML" | sed 's/save_every_n_epochs = //')
                            RANK=$(grep "^rank = " "$MODEL_TOML" | sed 's/rank = //')
                            LR=$(grep "^lr = " "$MODEL_TOML" | sed 's/lr = //')
                            OPTIMIZER_TYPE=$(grep "^type = " "$MODEL_TOML" | grep -A5 "\[optimizer\]" | grep "^type = " | sed "s/type = '//;s/'//")

                            # Set defaults if not found
                            [ -z "$EPOCHS" ] && EPOCHS="1000 (default)"
                            [ -z "$SAVE_EVERY" ] && SAVE_EVERY="2 (default)"
                            [ -z "$RANK" ] && RANK="32 (default)"
                            [ -z "$LR" ] && LR="2e-5 (default)"
                            [ -z "$OPTIMIZER_TYPE" ] && OPTIMIZER_TYPE="adamw_optimi (default)"
                        else
                            # Fallback defaults if TOML file not found
                            EPOCHS="1000 (default)"
                            SAVE_EVERY="2 (default)"
                            RANK="32 (default)"
                            LR="2e-5 (default)"
                            OPTIMIZER_TYPE="adamw_optimi (default)"
                        fi

                        # Display updated configuration for confirmation
                        print_header "Updated Training Configuration"
                        echo ""
                        echo -e "${BOLD}Model:${NC} $MODEL_NAME"
                        echo -e "${BOLD}Resolution:${NC} ${RESOLUTION}x${RESOLUTION}"
                        echo ""
                        echo -e "${BOLD}Updated Training Parameters:${NC}"
                        echo "  📊 Epochs: $EPOCHS"
                        echo "  💾 Save Every: $SAVE_EVERY epochs"
                        echo "  🎛️  LoRA Rank: $RANK"
                        echo "  📈 Learning Rate: $LR"
                        echo "  ⚙️  Optimizer: $OPTIMIZER_TYPE"
                        echo ""

                        while true; do
                            read -p "Do these updated settings look correct? (yes/no): " settings_confirm
                            case $settings_confirm in
                                yes|YES|y|Y)
                                    print_success "Settings confirmed. Proceeding with training..."
                                    break 2  # Break out of both loops
                                    ;;
                                no|NO|n|N)
                                    print_info "Please modify the configuration files again."
                                    echo ""
                                    break  # Go back to configuration loop
                                    ;;
                                *)
                                    print_error "Please enter 'yes' or 'no'."
                                    ;;
                            esac
                        done
                        ;;
                    no|NO|n|N)
                        print_info "Take your time configuring the settings."
                        ;;
                    *)
                        print_error "Please enter 'yes' or 'no'."
                        ;;
                esac
            done
            break
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

echo ""

# Check if image captioning is still running
if [ "$CAPTION_MODE" = "images" ] || [ "$CAPTION_MODE" = "both" ]; then
    # Image captioning was already handled in the captioning section above
    # No need to check again here

    # Prompt user to inspect image captions
    print_header "Caption Inspection"
    echo ""
    print_info "Please manually inspect the generated captions in:"
    echo "  /workspace/kakwan/image_dataset_here"
    echo ""
    print_warning "Check that the captions are accurate and appropriate for your training data."
    echo ""

    while true; do
        read -p "Have you reviewed the image captions and are ready to proceed? (yes/no): " inspect_choice
        case $inspect_choice in
            yes|YES|y|Y)
                print_success "Image captions approved. Proceeding to training..."
                break
                ;;
            no|NO|n|N)
                print_info "Please review the captions and run this script again when ready."
                exit 0
                ;;
            *)
                print_error "Please enter 'yes' or 'no'."
                ;;
        esac
    done
    echo ""
fi

# Check video captions if applicable
if [ "$CAPTION_MODE" = "videos" ] || [ "$CAPTION_MODE" = "both" ]; then
    # Video captioning was already handled in the captioning section above
    # No need to check again here

    print_header "Video Caption Inspection"
    echo ""
    print_info "Please manually inspect the generated video captions in:"
    echo "  /workspace/kakwan/video_dataset_here"
    echo ""
    print_warning "Check that the video captions are accurate and appropriate for your training data."
    echo ""

    while true; do
        read -p "Have you reviewed the video captions and are ready to proceed? (yes/no): " video_inspect_choice
        case $video_inspect_choice in
            yes|YES|y|Y)
                print_success "Video captions approved. Proceeding to training..."
                break
                ;;
            no|NO|n|N)
                print_info "Please review the captions and run this script again when ready."
                exit 0
                ;;
            *)
                print_error "Please enter 'yes' or 'no'."
                ;;
        esac
    done
    echo ""
fi

# Start WAN 2.2 AIO LoRA training
print_header "Starting WAN 2.2 AIO LoRA Training"
echo ""

print_info "Changing to WAN 2.2 training directory..."
cd "/workspace/kakwan/wan2.2_lora_training"

print_info "Starting AIO-compatible LoRA training with $MODEL_NAME..."
echo ""

print_warning "Training is starting. This may take several hours depending on your dataset size."
print_info "You can monitor progress in the console output below."
echo ""

# Start WAN 2.2 AIO training
bash setup_and_train_musubi.sh

print_success "WAN 2.2 AIO LoRA training completed!"
echo ""
print_info "Your trained LoRA is saved in: /workspace/kakwan/wan2.2_lora_training/output/"