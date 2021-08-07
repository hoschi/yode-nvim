#! /bin/bash

rm lua/yode-nvim/deps/*.lua
wget -O lua/yode-nvim/deps/lamda.lua https://raw.githubusercontent.com/moriyalb/lamda/fac503910cbdbecd9a5af71a19ed6e80dd8553f1/dist/lamda.lua

echo 'finished ✔'
