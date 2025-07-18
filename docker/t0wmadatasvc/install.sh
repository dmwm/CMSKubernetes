#!/bin/bash
#No longer using rpm for packaging t0wmadatasvc

TAG=2.1.1
pip install --upgrade pip
pip install --no-cache-dir git+https://github.com/dmwm/t0wmadatasvc.git@$TAG

