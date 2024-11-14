*TensorFlow-Ubuntu-Build-Script*


*** Work ***



Ce dépôt contient un script pour compiler TensorFlow à partir du code source sur une machine Ubuntu. Il a été optimisé pour utiliser les instructions AVX2 et FMA, garantissant ainsi des performances accrues pour les processeurs compatibles.
Prérequis

    Système d'exploitation : Ubuntu 24.04 ou version plus récente.
    Outils de compilation :
        Bazel (version compatible avec la version de TensorFlow souhaitée)
        Python (recommandé : 3.12)
        Pip et virtualenv
    Dépendances supplémentaires :
        Git
        Python packages : numpy, cython, setuptools

Installation
1. Cloner le dépôt TensorFlow

git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout <version-de-tensorflow>

2. Configurer les sous-modules Git

git submodule update --init --recursive

3. Exécuter le script de configuration

Lancez le script de configuration avec les droits administrateur pour générer correctement les fichiers de configuration nécessaires.

sudo ./configure

Le script de configuration vous demandera d'indiquer les chemins vers Python et ses bibliothèques ainsi que de définir les options d'optimisation (ex : AVX2, FMA, CUDA si GPU).
4. Compiler TensorFlow

Pour compiler le package Python, exécutez le script principal du dépôt :

./build_tensorflow_avx2_fma_orig.sh

Ce script :

    Vérifie la compatibilité AVX2 et FMA.
    Installe les dépendances.
    Crée un environnement virtuel Python pour isoler les bibliothèques.
    Exécute la compilation avec Bazel.
    Produit un fichier .whl prêt à être installé.

5. Installer le package TensorFlow

Une fois la compilation terminée, installez le package Python généré :

pip install /home/viking/tensorflow_pkg/tensorflow-*.whl

Dépannage
Erreurs courantes

    Erreur de permission lors de la génération des fichiers de configuration
    Si le fichier .tf_configure.bazelrc n’est pas généré correctement, exécutez sudo ./configure.

    Cible build_pip_package introuvable
    Si l'erreur no such target //tensorflow/tools/pip_package:build_pip_package apparaît, assurez-vous que les sous-modules Git sont correctement initialisés en exécutant git submodule update --init --recursive.

    Incompatibilité de version de Bazel
    Vérifiez la version de Bazel avec bazel --version et comparez-la avec celle recommandée pour la version de TensorFlow. Ajustez si nécessaire.

Commande de Debug

Pour lister les cibles disponibles dans Bazel :

bazel query "//tensorflow/tools/pip_package:*"

Auteurs

Ce dépôt a été mis en place pour faciliter la compilation optimisée de TensorFlow sous Ubuntu.

Ce README.md couvre les étapes principales et donne des instructions pour la résolution des erreurs courantes.
