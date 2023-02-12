#!/bin/bash

#time ./kas-container build kas-iot2050-example.yml:kas/opt/sdk.yml
#time ./kas-container build kas-iot2050-example.yml --target bazel-bootstrap

time ./kas-container build kas-iot2050-swupdate.yml ${1:+--target $1}
