#!/bin/bash

# Variables de configuration
TF_VERSION="2.18.0"  # Choisissez la version TensorFlow souhaitée
NUM_CORES=$(nproc)  # Utilisation de tous les coeurs disponibles

# 1. Vérification et installation des dépendances de base
echo -e "\033[1mVérification des dépendances de base...\033[0m"
DEPENDENCIES=("curl" "git" "pip" "cpuinfo" "build-essential" "python3-dev" "python3-pip" "python3-venv")

for package in "${DEPENDENCIES[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        echo -e "\033[1mInstallation de $package...\033[0m"
        sudo apt update
        sudo apt install -y "$package"
    fi
done

# Installation de Bazelisk (alternative recommandée pour gérer Bazel)
if ! command -v bazel &> /dev/null; then
    echo -e "\033[1mInstallation de Bazelisk...\033[0m"
    sudo curl -L https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o /usr/local/bin/bazel
    sudo chmod +x /usr/local/bin/bazel
fi

# 2. Création d'un environnement virtuel Python
echo -e "\033[1mCréation d'un environnement virtuel Python pour isoler les dépendances...\033[0m"
python3 -m venv tf_build_env
source tf_build_env/bin/activate

# 3. Vérification de la compatibilité AVX2 et FMA
if ! grep -q "avx2" /proc/cpuinfo || ! grep -q "fma" /proc/cpuinfo; then
    echo -e "\033[1mErreur : Votre processeur ne supporte pas AVX2 et FMA. Build annulée.\033[0m"
    exit 1
fi

echo -e "\033[1mCompatibilité AVX2 et FMA confirmée. Début de la compilation.\033[0m"

# 4. Installation de distutils et numpy dans l'environnement virtuel
pip install --upgrade pip setuptools
if ! python -c "import distutils" &> /dev/null; then
    echo -e "\033[1mInstallation de distutils...\033[0m"
    pip install distutils
    pip install --upgrade pip setuptools
fi

# Installation de numpy, requis pour la compilation
pip install cython numpy==2.0.0

# 5. Clonage du dépôt TensorFlow
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v$TF_VERSION

# 6. Configuration de la build TensorFlow
export PYTHON_BIN_PATH=$(which python)
export HERMETIC_PYTHON_VERSION=3.10
export TF_ENABLE_XLA=1  # Active l'optimisation XLA
export TF_NEED_CLANG=0
export CC_OPT_FLAGS="-march=native -mavx2 -mfma"  # Optimisation AVX2 et FMA
export TF_NEED_CUDA=0   # Désactiver CUDA pour une build CPU uniquement

# Lancement du script de configuration TensorFlow
yes "" | ./configure

# 7. Build TensorFlow avec Bazel en spécifiant les flags d'optimisation AVX2 et FMA
echo -e "\033[1m*********** Purge Bazel    ************\033[0m"
bazel clean

echo -e "\033[1m*********** Build Bazel    ************\033[0m"
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package \
            --local_ram_resources="HOST_RAM*.5" \
            --jobs="HOST_CPUS*.5"
            
 #           $NUM_CORES

# 8. Création du package pip
mkdir -p ~/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package ~/tensorflow_pkg

# 9. Installation du package TensorFlow compilé dans l'environnement virtuel
pip install ~/tensorflow_pkg/tensorflow-*.whl

echo -e "\033[1mLa build de TensorFlow avec AVX2 et FMA est terminée.\033[0m"
echo -e "\033[1mPour utiliser TensorFlow, activez l'environnement virtuel avec : source tf_build_env/bin/activate\033[0m" 
