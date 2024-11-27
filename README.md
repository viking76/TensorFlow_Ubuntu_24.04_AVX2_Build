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

To build from scratch:

    wget https://raw.githubusercontent.com/viking76/TensorFlow_Ubuntu_AVX2_Build/refs/heads/main/tensorflow_builder.sh
    sh ./tensorflow_builder.sh
    
Pour installer directement le binaire comiler sur un 3900x

    curl -L https://github.com/viking76/TensorFlow-Ubuntu-Build-Script/releases/download/TF2.17/tensorflow_cpu-2.17.1-cp312-cp312-linux_x86_64.whl
    sudo pip install ~/tensorflow_cpu*.whl

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



Auteurs

Ce dépôt a été mis en place pour faciliter la compilation optimisée de TensorFlow sous Ubuntu.

Ce README.md couvre les étapes principales et donne des instructions pour la résolution des erreurs courantes.


License

Apache License 2.0
