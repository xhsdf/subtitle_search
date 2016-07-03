#!/bin/bash

input=$1
output=$2
title=${3-$(basename "$input")}

./extract.rb "$input" "$output" "$title"
./subs_to_json.rb "$output/$title" "$title" --compact
