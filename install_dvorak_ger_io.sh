#!/bin/bash
mkdir -p /usr/local/share/kbd/keymaps
cp /rice/dvorak_ger_io.kmap /usr/local/share/kbd/keymaps
loadkeys /usr/local/share/kbd/keymaps/dvorak_ger_io.kmap
echo KEYMAP=/usr/local/share/kbd/keymaps/dvorak_ger_io.kmap > /etc/vconsole.conf
