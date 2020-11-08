#!/bin/bash

podman run -i --rm quay.io/coreos/ct:latest-dev --pretty --strict < ignition.yml
