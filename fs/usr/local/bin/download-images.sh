#!/usr/bin/env bash
mkdir -p /root/Pictures
for i in {1..10}; do wget http://loremflickr.com/800/600 -O "/root/Pictures/$i.jpg"; done