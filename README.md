*TensorFlow-Ubuntu-Build-Script*


*** Work ***



Ce dépôt contient un script pour compiler TensorFlow à partir du code source sur une machine Ubuntu. Il a été optimisé pour utiliser les instructions AVX2 et FMA, garantissant ainsi des performances accrues pour les processeurs compatibles.

**Versions mises à jour (Juin 2025) :**
- TensorFlow 2.19.0 (dernière version stable)
- Bazelisk 1.26.0 (gestion automatique de Bazel)
- NumPy 2.2.6 (dernière version compatible)
- Six 1.17.0 (dernière version)

Prérequis

    Système d'exploitation : Ubuntu 20.04 LTS ou plus récent (24.04 LTS recommandé)
    Vérification automatique de la version du système d'exploitation
    Outils de compilation :
        Bazelisk (gère automatiquement la version de Bazel compatible)
        Python (recommandé : 3.12)
        Pip et virtualenv
    Dépendances supplémentaires :
        Git
        Bibliothèques mathématiques : libomp-dev, libopenblas-dev, liblapack-dev, libeigen3-dev, libblas-dev, libatlas-base-dev
        Outils système : cpuinfo
        Python packages : numpy, six

To build from scratch:

    wget https://raw.githubusercontent.com/viking76/TensorFlow_Ubuntu_AVX2_Build/refs/heads/main/tensorflow_builder.sh
    sh ./tensorflow_builder.sh
    
Pour installer directement le binaire compilé sur un 3900x

    curl -L https://github.com/viking76/TensorFlow-Ubuntu-Build-Script/releases/download/TF2.19/tensorflow_cpu-2.19.0-cp312-cp312-linux_x86_64.whl
    sudo pip install ~/tensorflow_cpu*.whl

### 🚀 Build avec support GPU (NVIDIA CUDA)

Pour compiler TensorFlow **avec support GPU**, utilisez le script dédié :

    wget https://raw.githubusercontent.com/viking76/TensorFlow_Ubuntu_AVX2_Build/refs/heads/main/tensorflow_builder_gpu.sh
    sh ./tensorflow_builder_gpu.sh

**Prérequis GPU :**
- Carte graphique NVIDIA compatible (architecture Pascal ou supérieure)
- Pilotes NVIDIA installés (`nvidia-driver-535` recommandé)
- CUDA Toolkit **12.3** (requis pour TensorFlow 2.19.0)
- cuDNN **8.9** (requis pour TensorFlow 2.19.0)

Le script vérifie automatiquement la présence de CUDA et cuDNN et propose de les installer si nécessaire.

Installation
1. Cloner le dépôt TensorFlow

    git clone https://github.com/viking76/TensorFlow-Ubuntu-Build-Script.git
    cd TensorFlow-Ubuntu
    ./tensorflow_build.sh



Le script de configuration vous demandera d'indiquer les chemins vers Python et ses bibliothèques ainsi que de définir les options d'optimisation (ex : AVX2, FMA, CUDA si GPU).


Ce script :

    Vérifie la compatibilité AVX2 et FMA.
    Installe les dépendances.
    Crée un environnement virtuel Python pour isoler les bibliothèques.
    Exécute la compilation avec Bazel.
    Produit un fichier .whl prêt à être installé.
    Installe le package TensorFlow


Dépannage
Erreurs courantes

    Erreur de permission lors de la génération des fichiers de configuration
    Incompatibilité de version de Bazel
    Vérifiez la version de Bazel avec bazel --version et comparez-la avec celle recommandée pour la version de TensorFlow. Ajustez si nécessaire.

### ⚠️ Dépannage GPU

- **Erreur CUDA non trouvé** : Vérifiez que `nvcc --version` fonctionne. Si non, installez CUDA Toolkit 12.3.
- **Erreur cuDNN non trouvé** : Vérifiez que `/usr/include/cudnn_version.h` existe. Installez `libcudnn8-dev` si nécessaire.
- **Incompatibilité de version CUDA** : TensorFlow 2.19.0 nécessite **CUDA 12.3** et **cuDNN 8.9**. Utilisez `sudo apt install nvidia-cuda-toolkit=12.3` pour forcer la version.
- **Pilotes NVIDIA manquants** : Exécutez `nvidia-smi` pour vérifier. Installez avec `sudo ubuntu-drivers autoinstall`.



Auteurs

Ce dépôt a été mis en place pour faciliter la compilation optimisée de TensorFlow sous Ubuntu.

Ce README.md couvre les étapes principales et donne des instructions pour la résolution des erreurs courantes.


License

Apache License 2.0
