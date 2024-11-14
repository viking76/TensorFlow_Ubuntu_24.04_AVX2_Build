#!/bin/bash

# Configuration des versions
TF_VERSION="2.17.1"                 # Version TensorFlow souhaitée
BAZELISK_VERSION="6.5.0"            # Version de Bazelisk (gère Bazel)
NUMPY_VERSION="2.1.2"              # Version de Numpy
SIX_VERSION="1.15.0"                # Version de Six
NUM_CORES=$(nproc) 
DEPENDENCIES=("curl" "git" "pip" "cpuinfo" "build-essential" "patchelf" "python3-full" "python3-dev" "python3-distutils" "python3-venv" "llvm-17" "clang-17")

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
    curl -L https://github.com/bazelbuild/bazelisk/releases/download/$BAZELISK_VERSION/bazelisk-linux-amd64 -o /usr/local/bin/bazel
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
export CC_OPT_FLAGS="-march=native -mavx2 -mfma"  # Optimisation AVX2 et FMA
export TF_NEED_CUDA=0   # Désactiver CUDA pour une build CPU uniquement
export TF_NEED_CLANG=1
export TF_PYTHON_VERSION=3.12
# Lancement du script de configuration TensorFlow
yes "" | ./configure

# 8. Build TensorFlow avec Bazel en spécifiant les flags d'optimisation AVX2 et FMA
echo -e "\033[1mBuilding TensorFlow with Bazel (AVX2 and FMA optimization)...\033[0m"
bazel build --copt=-mavx2 --copt=-mfma --config=opt //tensorflow/tools/pip_package:wheel \
	    --repo_env=WHEEL_NAME=tensorflow_cpu \
            --local_ram_resources=2048 \
            --jobs=$NUM_CORES

# 9. Création du package pip
echo -e "\033[1mCreating pip package for TensorFlow...\033[0m"
mkdir -p ~/tensorflow_pkg
sudo mv ~/tensorflow/bazel-bin/tensorflow/tools/pip_package/wheel_house/* ~/tensorflow_pkg

# 10. Installation du package TensorFlow compilé dans l'environnement virtuel
echo -e "\033[1mInstalling the compiled TensorFlow package...\033[0m"
pip install ~/tensorflow_pkg/tensorflow_cpu*.whl

# 11. Désactivation de l'environnement virtuel
deactivate

echo -e "\033[1mTensorFlow build with AVX2 and FMA optimization completed successfully.\033[0m"
echo -e "\033[1mTo use TensorFlow, activate the virtual environment with: source tf_build_env/bin/activate\033[0m"
