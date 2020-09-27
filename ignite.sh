#!/bin/bash

podman run -i --rm quay.io/coreos/fcct:release --pretty --strict < ignition.yml
