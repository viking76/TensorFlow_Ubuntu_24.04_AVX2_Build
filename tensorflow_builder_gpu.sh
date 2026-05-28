#!/bin/bash

# =============================================================================
# TensorFlow GPU Builder Script for Ubuntu 24.04
# Optimisé pour AVX2, FMA et support CUDA (GPU NVIDIA)
# Version: 1.0
# Auteur: Adapté depuis tensorflow_builder.sh
# =============================================================================

# Configuration des versions
TF_VERSION="2.19.0"                 # Version TensorFlow souhaitée
BAZELISK_VERSION="1.26.0"           # Version de Bazelisk (gère Bazel)
NUMPY_VERSION="2.2.6"              # Version de Numpy
SIX_VERSION="1.17.0"                # Version de Six
NUM_CORES=$(nproc)

# Versions CUDA requises pour TensorFlow 2.19.0
CUDA_VERSION_REQUIRED="12.3"       # Version de CUDA requise
CUDNN_VERSION_REQUIRED="8.9"       # Version de cuDNN requise

# Dépendances de base (CPU + GPU)
DEPENDENCIES=("curl" "git" "pip" "build-essential" "patchelf" "python3-full" "python3-dev" "python3-distutils" "python3-venv" "libopenblas-dev" "libomp-dev" "liblapack-dev" "libeigen3-dev" "libblas-dev" "libatlas-base-dev" "cpuinfo" "llvm-17" "clang-17")

# Dépendances GPU (seront installées si CUDA n'est pas détecté)
GPU_DEPENDENCIES=("nvidia-driver-535" "nvidia-cuda-toolkit" "libcudnn8" "libcudnn8-dev" "nvidia-cuda-dev")

# =============================================================================
# 0. Vérification de la version Ubuntu/Debian
# =============================================================================
echo -e "\033[1mChecking operating system version...\033[0m"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Operating System: $PRETTY_NAME"
    
    if [[ "$ID" == "ubuntu" ]]; then
        UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d. -f1,2)
        echo "Ubuntu version detected: $UBUNTU_VERSION"
        
        if [[ $(echo "$UBUNTU_VERSION >= 20.04" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            echo -e "\033[32m✓ Ubuntu version $UBUNTU_VERSION is supported\033[0m"
        else
            echo -e "\033[33m⚠ Warning: Ubuntu $UBUNTU_VERSION may not be fully supported. Recommended: Ubuntu 20.04 or newer\033[0m"
            read -p "Do you want to continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Build aborted by user."
                exit 1
            fi
        fi
    elif [[ "$ID" == "debian" ]]; then
        echo -e "\033[33m⚠ Debian detected. This script is optimized for Ubuntu but may work on Debian.\033[0m"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Build aborted by user."
            exit 1
        fi
    else
        echo -e "\033[31m✗ Unsupported operating system: $PRETTY_NAME\033[0m"
        echo "This script is designed for Ubuntu 20.04 or newer."
        exit 1
    fi
else
    echo -e "\033[31m✗ Cannot determine operating system version\033[0m"
    exit 1
fi

# =============================================================================
# 1. Vérification et installation des dépendances de base
# =============================================================================
echo -e "\033[1mChecking base dependencies...\033[0m"
for package in "${DEPENDENCIES[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        echo -e "\033[1mInstalling $package...\033[0m"
        sudo apt update
        sudo apt install -y "$package"
    fi
done

# =============================================================================
# 2. Vérification de CUDA, cuDNN et des pilotes NVIDIA
# =============================================================================
echo -e "\033[1mChecking GPU dependencies (CUDA, cuDNN, NVIDIA drivers)...\033[0m"

# Vérifier les pilotes NVIDIA
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "\033[33m⚠ NVIDIA drivers are not installed.\033[0m"
    read -p "Do you want to install NVIDIA drivers and CUDA toolkit? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\033[1mInstalling NVIDIA drivers and CUDA toolkit...\033[0m"
        sudo ubuntu-drivers autoinstall
        sudo apt update
        for package in "${GPU_DEPENDENCIES[@]}"; do
            if ! dpkg -s "$package" >/dev/null 2>&1; then
                echo -e "\033[1mInstalling $package...\033[0m"
                sudo apt install -y "$package"
            fi
        done
        
        # Redémarrer pour charger les pilotes NVIDIA
        echo -e "\033[33m⚠ NVIDIA drivers installed. A system reboot is recommended.\033[0m"
        read -p "Do you want to continue without rebooting? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Please reboot your system and run this script again."
            exit 1
        fi
    else
        echo -e "\033[31m✗ GPU support requires NVIDIA drivers and CUDA toolkit.\033[0m"
        echo "Build aborted. Use tensorflow_builder.sh for CPU-only build."
        exit 1
    fi
else
    echo -e "\033[32m✓ NVIDIA drivers are installed.\033[0m"
fi

# Vérifier CUDA Toolkit
if ! command -v nvcc &> /dev/null; then
    echo -e "\033[31m✗ CUDA Toolkit is not installed.\033[0m"
    echo "GPU support requires CUDA $CUDA_VERSION_REQUIRED. Please install it first."
    exit 1
else
    CUDA_VERSION_INSTALLED=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d. -f1,2)
    echo "CUDA version detected: $CUDA_VERSION_INSTALLED"
    
    if [[ "$CUDA_VERSION_INSTALLED" != "$CUDA_VERSION_REQUIRED" ]]; then
        echo -e "\033[33m⚠ Warning: TensorFlow $TF_VERSION requires CUDA $CUDA_VERSION_REQUIRED, but CUDA $CUDA_VERSION_INSTALLED is installed.\033[0m"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Build aborted by user."
            exit 1
        fi
    else
        echo -e "\033[32m✓ CUDA version $CUDA_VERSION_INSTALLED is compatible.\033[0m"
    fi
fi

# Vérifier cuDNN
CUDNN_HEADER="/usr/include/cudnn_version.h"
if [ -f "$CUDNN_HEADER" ]; then
    CUDNN_VERSION_INSTALLED=$(grep "CUDNN_MAJOR" -A 2 "$CUDNN_HEADER" | grep "CUDNN_MINOR" -A 1 | grep "CUDNN_PATCHLEVEL" -A 1 | awk '{print $3}' | tr '\n' '.' | sed 's/.$//')
    echo "cuDNN version detected: $CUDNN_VERSION_INSTALLED"
    
    if [[ "$CUDNN_VERSION_INSTALLED" != "$CUDNN_VERSION_REQUIRED" ]]; then
        echo -e "\033[33m⚠ Warning: TensorFlow $TF_VERSION requires cuDNN $CUDNN_VERSION_REQUIRED, but cuDNN $CUDNN_VERSION_INSTALLED is installed.\033[0m"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Build aborted by user."
            exit 1
        fi
    else
        echo -e "\033[32m✓ cuDNN version $CUDNN_VERSION_INSTALLED is compatible.\033[0m"
    fi
else
    echo -e "\033[31m✗ cuDNN is not installed.\033[0m"
    echo "GPU support requires cuDNN $CUDNN_VERSION_REQUIRED. Please install it first."
    exit 1
fi

# Définir les chemins CUDA et cuDNN
export CUDA_HOME=$(dirname $(dirname $(which nvcc)))
export CUDNN_HOME="/usr/lib/x86_64-linux-gnu"
echo "CUDA_HOME: $CUDA_HOME"
echo "CUDNN_HOME: $CUDNN_HOME"

# =============================================================================
# 3. Vérification de la compatibilité AVX2 et FMA
# =============================================================================
if ! grep -q "avx2" /proc/cpuinfo || ! grep -q "fma" /proc/cpuinfo; then
    echo -e "\033[1mError: Your CPU does not support AVX2 and FMA. Build aborted.\033[0m"
    exit 1
fi

echo -e "\033[1mAVX2 and FMA compatibility confirmed.\033[0m"

# =============================================================================
# 4. Création et activation d'un environnement virtuel Python
# =============================================================================
echo -e "\033[1mCreating Python virtual environment...\033[0m"
python3 -m venv tf_build_env
source tf_build_env/bin/activate

# =============================================================================
# 5. Installation des paquets Python dans l'environnement virtuel
# =============================================================================
echo -e "\033[1mInstalling Python packages numpy and six...\033[0m"
pip install numpy==$NUMPY_VERSION six==$SIX_VERSION

# =============================================================================
# 6. Installation de Bazelisk (outil recommandé pour gérer Bazel)
# =============================================================================
if ! command -v bazel &> /dev/null; then
    echo -e "\033[1mInstalling Bazelisk version $BAZELISK_VERSION...\033[0m"
    curl -L https://github.com/bazelbuild/bazelisk/releases/download/v$BAZELISK_VERSION/bazelisk-linux-amd64 -o /usr/local/bin/bazel
    sudo chmod +x /usr/local/bin/bazel
fi

# =============================================================================
# 7. Clonage du dépôt TensorFlow
# =============================================================================
echo -e "\033[1mCloning TensorFlow version $TF_VERSION...\033[0m"
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v$TF_VERSION

# =============================================================================
# 8. Configuration de la build TensorFlow avec support GPU
# =============================================================================
echo -e "\033[1mConfiguring TensorFlow build with GPU support...\033[0m"

# Variables d'environnement pour la compilation GPU
export TF_ENABLE_XLA=1  # Active l'optimisation XLA
export CC_OPT_FLAGS="-march=x86-64-v3"  # Optimisation AVX2 et FMA
export TF_NEED_CUDA=1   # Activer CUDA pour le support GPU
export TF_NEED_CLANG=1
export TF_PYTHON_VERSION=3.12

# Versions CUDA et cuDNN pour TensorFlow 2.19.0
export TF_CUDA_VERSION="$CUDA_VERSION_REQUIRED"
export TF_CUDNN_VERSION="$CUDNN_VERSION_REQUIRED"
export TF_NEED_TENSORRT=0  # Désactiver TensorRT (optionnel)

# Chemins vers CUDA et cuDNN
export TF_CUDA_COMPUTE_CAPABILITIES=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | tr ',' ';' | sed 's/\.//g')
echo "Detected GPU compute capabilities: $TF_CUDA_COMPUTE_CAPABILITIES"

# Lancement du script de configuration TensorFlow
yes "" | ./configure

# =============================================================================
# 9. Build TensorFlow avec Bazel (AVX2, FMA et CUDA)
# =============================================================================
echo -e "\033[1mBuilding TensorFlow with Bazel (AVX2, FMA, and CUDA optimization)...\033[0m"
bazel build --copt=-mavx2 --copt=-mfma --config=opt --config=cuda \
            --repo_env=WHEEL_NAME=tensorflow_gpu \
            --local_ram_resources=2048 \
            --jobs=$NUM_CORES

# =============================================================================
# 10. Création du package pip
# =============================================================================
echo -e "\033[1mCreating pip package for TensorFlow GPU...\033[0m"
mkdir -p ~/tensorflow_pkg
rm ~/tensorflow_pkg/*
sudo mv ~/tensorflow/bazel-bin/tensorflow/tools/pip_package/wheel_house/* ~/tensorflow_pkg

# =============================================================================
# 11. Installation du package TensorFlow compilé dans l'environnement virtuel
# =============================================================================
echo -e "\033[1mFor installing the compiled TensorFlow GPU package...\033[0m"
echo -e "\033[1mpip install ~/tensorflow_pkg/tensorflow_gpu-$TF_VERSION*.whl\033[0m"

# =============================================================================
# 12. Désactivation de l'environnement virtuel
# =============================================================================
deactivate

echo -e "\033[1mTensorFlow build with AVX2, FMA, and GPU support completed successfully.\033[0m"
echo -e "\033[1mTo use TensorFlow, activate the virtual environment with: source tf_build_env/bin/activate\033[0m"
echo -e "\033[1mThen install the wheel: pip install ~/tensorflow_pkg/tensorflow_gpu-$TF_VERSION*.whl\033[0m"
echo -e "\033[1m****************************************************.\033[0m"
echo -e "\033[1m************* TensorFlow GPU Build Ready! ***********\033[0m"
echo -e "\033[1m****************************************************.\033[0m"
