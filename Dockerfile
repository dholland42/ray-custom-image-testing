ARG BASE_IMAGE="ubuntu:22.04"
FROM ${BASE_IMAGE}
# FROM directive resets ARG
ARG BASE_IMAGE
# If this arg is not "autoscaler" then no autoscaler requirements will be included
ARG AUTOSCALER="autoscaler"
ENV TZ=America/Los_Angeles
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# TODO(ilr) $HOME seems to point to result in "" instead of "/home/ray"
ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.12
ARG HOSTTYPE=${HOSTTYPE:-x86_64}

ARG RAY_UID=1000
ARG RAY_GID=100

RUN <<EOF
#!/bin/bash

set -euo pipefail

apt-get update -y
apt-get upgrade -y

APT_PKGS=(
    sudo
    tzdata
    git
    libjemalloc-dev
    wget
    cmake
    g++
    zlib1g-dev
    curl
)
if [[ "$AUTOSCALER" == "autoscaler" ]]; then
    APT_PKGS+=(
        tmux
        screen
        rsync
        netbase
        openssh-client
        gnupg
    )
fi

apt-get install -y "${APT_PKGS[@]}"

useradd -ms /bin/bash -d /home/ray ray --uid $RAY_UID --gid $RAY_GID
usermod -aG sudo ray
echo 'ray ALL=NOPASSWD: ALL' >> /etc/sudoers

EOF


USER $RAY_UID

ENV HOME=/home/ray

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# COPY python/requirements_compiled.txt /home/ray/requirements_compiled.txt

SHELL ["/bin/bash", "-c"]

WORKDIR $HOME

ENV PATH="$HOME/.venv/bin:$HOME/.local/bin:$PATH"

ADD pyproject.toml .
ADD uv.lock .
ADD .python-version .
RUN uv sync


CMD [ "bash" ]
