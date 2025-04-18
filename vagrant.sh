#!/bin/bash

# -- ! in development --
# This script is used to provision a Vagrant VM with a specific configuration.
# It installs necessary packages, sets up the environment, and configures the VM.
#
SERVICES="docker-compose,mariadb,nginx" PASSED_ARGS=" " vagrant up vmdocker --provision