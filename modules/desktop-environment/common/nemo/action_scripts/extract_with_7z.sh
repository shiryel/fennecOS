#/usr/bin/env bash

echo $1

for i in "$1"; do
  7z -y -o"$(echo $i | sed "s/\.[^.]*$//")" x "$(echo $i)"
done
