#!/bin/sh


make SPHINXOPTS='-t public' html
touch build/html/.nojekyll
