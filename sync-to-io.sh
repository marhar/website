#!/bin/bash

cd /Users/marhar/g/website
hugo
rm -rf /Users/marhar/g/marhar.github.io/*
cp -rp /Users/marhar/g/website/public/* /Users/marhar/g/marhar.github.io

cd /Users/marhar/g/marhar.github.io
git commit -am "$1"
git push
