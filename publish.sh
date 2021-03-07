#!/bin/sh


make SPHINXOPTS='-t public' html
cp -r build/html/* docs
touch docs/.nojekyll

