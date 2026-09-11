#!/bin/bash

cd $(dirname $(realpath $0))

which esphome || source ../venv/bin/activate

esphome compile big.yaml && esphome upload big.yaml --device 192.168.178.108 && esphome logs big.yaml --device 192.168.178.108
