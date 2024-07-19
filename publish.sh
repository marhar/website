#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo usage: $0 comment
  exit 1
fi

cd /Users/marhar/g/website
hugo
rm -rf /Users/marhar/g/marhar.github.io/*
cp -rp /Users/marhar/g/website/public/* /Users/marhar/g/marhar.github.io

cd /Users/marhar/g/marhar.github.io
git add .
git commit -m "$1"
git push
