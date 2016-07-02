#!/bin/bash

# 1 = Folder or file
# 2 = series title
# 3 = output folder

./extract.rb "$1" "$2" "$3"
./subs_to_json.rb "$3/$2" "$2" --remove-clean
