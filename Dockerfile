# Set up an Ansible Controller with DebOps support as a Docker container
#
# Originally created by:
# Copyright (C) 2017-2019 Maciej Delmanowski <drybjed@gmail.com>
# Copyright (C) 2017-2019 DebOps <https://debops.org/>, pbo
#
# Maintained by:
# Copyright (C) 2024 Vojtěch Sajdl <vojtech@sajdl.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later


# Basic usage:
#
#     docker build -t debops .
#     docker run --name <container> -h controller.example.org -i -t debops


FROM debian:bookworm-slim

LABEL maintainer="Vojtěch Sajdl <vojtech@sajdl.com>" \
      description="Unofficial DebOps Docker image" \
      homepage="https://github.com/pryx/debops-docker"

ARG DEBOPS_VERSION=master

# Build dependencies are required to compile some Python packages (e.g. python-ldap)
RUN apt-get -q update \
    && DEBIAN_FRONTEND=noninteractive apt-get \
       --no-install-recommends -yq install \
       build-essential \
       python3-dev \
       python3-venv \
       python3-requests \
       python3-dateutil \
       pipx \
       libffi-dev \
       libssl-dev \
       libsasl2-dev \
       libldap2-dev \
       iproute2 \
       iputils-ping \
       vim \
       openssh-client \
       procps \
       sudo \
       tree \
       sshpass \
       git \
       man-db \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /root/.cache/*

RUN groupadd --system admins \
    && echo "%admins ALL = (ALL:ALL) NOPASSWD: SETENV: ALL" > /etc/sudoers.d/admins \
    && chmod 0440 /etc/sudoers.d/admins \
    && useradd --user-group --create-home --shell /bin/bash \
       --home-dir /home/ansible --groups admins ansible

COPY docker-entrypoint /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

USER ansible
WORKDIR /home/ansible

ENV USER=ansible \
    PATH="/home/ansible/.local/bin:$PATH"

RUN if [ "$DEBOPS_VERSION" = "master" ]; then \
        pipx install \
            "debops @ git+https://github.com/debops/debops.git@master"; \
    else \
        pipx install "debops==${DEBOPS_VERSION#v}"; \
    fi \
    && pipx inject --include-apps debops "ansible>=11,<12" "ansible-core<2.18.1" \
    && pipx inject debops "netaddr" "jmespath" "passlib" "dnspython" "requests"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/bin/bash"]
