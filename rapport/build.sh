#!/bin/bash
# Génère rapport.pdf depuis rapport.tex + rapport.cls
# Deux passes pdflatex pour la table des matières et les références croisées.
set -e

cd "$(dirname "$0")"

echo "=== Compilation du rapport (passe 1/2) ==="
pdflatex -interaction=nonstopmode rapport.tex > /dev/null

echo "=== Nettoyage des fichiers temporaires ==="
rm -f rapport.aux rapport.log rapport.out rapport.toc rapport.nlo rapport.lof

echo "=== Terminé : rapport.pdf généré ==="
