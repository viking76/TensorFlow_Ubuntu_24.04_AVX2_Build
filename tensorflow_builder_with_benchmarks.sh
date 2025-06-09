
#!/bin/bash

# Configuration des versions
TF_VERSION="2.19.0"                 # Version TensorFlow souhaitée
BAZELISK_VERSION="1.26.0"           # Version de Bazelisk (gère Bazel)
NUMPY_VERSION="2.2.6"              # Version de Numpy
SIX_VERSION="1.17.0"                # Version de Six
NUM_CORES=$(nproc)
DEPENDENCIES=("curl" "git" "pip" "build-essential" "patchelf" "python3-full" "python3-dev" "python3-distutils" "python3-venv" "libopenblas-dev" "libomp-dev" "liblapack-dev" "libeigen3-dev" "libblas-dev" "libatlas-base-dev" "cpuinfo" "llvm-17" "clang-17")

# 0. Vérification de la version Ubuntu/Debian
echo -e "\033[1mChecking operating system version...\033[0m"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Operating System: $PRETTY_NAME"

    if [[ "$ID" == "ubuntu" ]]; then
        # Extract Ubuntu version (e.g., "24.04" from "24.04.1")
        UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d. -f1,2)
        echo "Ubuntu version detected: $UBUNTU_VERSION"

        # Check if Ubuntu version is 20.04 or newer (minimum recommended)
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

# 1. Vérification et installation des dépendances de base
echo -e "\033[1mChecking base dependencies...\033[0m"
for package in "${DEPENDENCIES[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        echo -e "\033[1mInstalling $package...\033[0m"
        sudo apt update
        sudo apt install -y "$package"
    fi
done

# 2. Création et activation d'un environnement virtuel Python
echo -e "\033[1mCreating Python virtual environment...\033[0m"
python3 -m venv tf_build_env
source tf_build_env/bin/activate

# 3. Installation des paquets Python dans l'environnement virtuel
echo -e "\033[1mInstalling Python packages numpy and six...\033[0m"
pip install numpy==$NUMPY_VERSION six==$SIX_VERSION

# 4. Installation de Bazelisk (outil recommandé pour gérer Bazel)
if ! command -v bazel &> /dev/null; then
    echo -e "\033[1mInstalling Bazelisk version $BAZELISK_VERSION...\033[0m"
    curl -L https://github.com/bazelbuild/bazelisk/releases/download/v$BAZELISK_VERSION/bazelisk-linux-amd64 -o /usr/local/bin/bazel
    sudo chmod +x /usr/local/bin/bazel
fi

# 5. Vérification de la compatibilité AVX2 et FMA
if ! grep -q "avx2" /proc/cpuinfo || ! grep -q "fma" /proc/cpuinfo; then
    echo -e "\033[1mError: Your CPU does not support AVX2 and FMA. Build aborted.\033[0m"
    exit 1
fi

echo -e "\033[1mAVX2 and FMA compatibility confirmed. Starting build.\033[0m"

# 6. Clonage du dépôt TensorFlow
echo -e "\033[1mCloning TensorFlow version $TF_VERSION...\033[0m"
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v$TF_VERSION

# 7. Configuration de la build TensorFlow
echo -e "\033[1mConfiguring TensorFlow build...\033[0m"
export TF_ENABLE_XLA=1  # Active l'optimisation XLA
export CC_OPT_FLAGS="-march=x86-64-v3" #-mavx2 -mfma  # Optimisation AVX2 et FMA voir https://github.com/HenrikBengtsson/x86-64-level
export TF_NEED_CUDA=0   # Désactiver CUDA pour une build CPU uniquement
export TF_NEED_CLANG=1
export TF_PYTHON_VERSION=3.12
# Lancement du script de configuration TensorFlow
yes "" | ./configure

# 8. Benchmark avant l'installation de TensorFlow optimisé
echo -e "\033[1mRunning benchmark before TensorFlow installation...\033[0m"
python3 /workspace/TensorFlow_Ubuntu_24.04_AVX2_Build/advanced_benchmark.py

# 9. Build TensorFlow avec Bazel en spécifiant les flags d'optimisation AVX2 et FMA
echo -e "\033[1mBuilding TensorFlow with Bazel (AVX2 and FMA optimization)...\033[0m"
bazel build --copt=-mavx2 --copt=-mfma --config=opt //tensorflow/tools/pip_package:wheel \
            --repo_env=WHEEL_NAME=tensorflow_cpu \
            --local_ram_resources=2048 \
            --jobs=$NUM_CORES

# 10. Création du package pip
echo -e "\033[1mCreating pip package for TensorFlow...\033[0m"
mkdir -p ~/tensorflow_pkg
rm ~/tensorflow_pkg/*
sudo mv ~/tensorflow/bazel-bin/tensorflow/tools/pip_package/wheel_house/* ~/tensorflow_pkg

# 11. Installation du package TensorFlow compilé dans l'environnement virtuel
echo -e "\033[1mInstalling the compiled TensorFlow package...\033[0m"
pip install ~/tensorflow_pkg/tensorflow_cpu-$TF_VERSION*.whl

# 12. Benchmark après l'installation de TensorFlow optimisé
echo -e "\033[1mRunning benchmark after TensorFlow installation...\033[0m"
python3 /workspace/TensorFlow_Ubuntu_24.04_AVX2_Build/advanced_benchmark.py

# 13. Désactivation de l'environnement virtuel
deactivate

echo -e "\033[1mTensorFlow build with AVX2 and FMA optimization completed successfully.\033[0m"
echo -e "\033[1mTo use TensorFlow, activate the virtual environment with: source tf_build_env/bin/activate\033[0m"
echo -e "\033[1m****************************************************.\033[0m"
echo -e "\033[1m****************  MERCI QUI ? **********************.\033[0m"
echo -e "\033[1m****************************************************.\033[0m"
