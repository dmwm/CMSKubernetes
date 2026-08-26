FROM ghcr.io/diracgrid/diracx/services:v0.3.0

USER root

# Switch Docker's default shell executor to bash
SHELL ["/bin/bash", "-c"]

# Source the activation script and install htcondor in the same subshell layer
RUN source /activate.sh && pip install --no-cache-dir htcondor
