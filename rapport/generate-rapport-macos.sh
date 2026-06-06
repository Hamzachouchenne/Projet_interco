#!/bin/sh
set -e

cd "$(dirname "$0")"

echo "Compilation du rapport..."
pdflatex -interaction=nonstopmode rapport.tex > /dev/null
pdflatex -interaction=nonstopmode rapport.tex > /dev/null

rm -f rapport.aux rapport.log rapport.out rapport.toc

echo "rapport.pdf généré."
