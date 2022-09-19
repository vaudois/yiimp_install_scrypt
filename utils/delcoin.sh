#!/bin/bash
################################################################################
# Program:
#   Remove all coin in Yiimp
# 
################################################################################

for line in $(cat coin.list); do
yiimp coin "$line" delete;
done
