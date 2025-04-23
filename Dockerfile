FROM ruby:3.4

ARG USER_UID
ARG USER_GID

# Setup an unprivileged user to fix docker host filesystem permissions
RUN useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m dev

# Common dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes --no-install-recommends \
  build-essential \
  ca-certificates \
  # gnupg2 \
  curl \
  less \
  git \
  openssl \
  # awscli \
  # ssh-client \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Create a directory for the app code
RUN mkdir -p /app
WORKDIR /app

RUN chown -R $USER_UID:$USER_GID /usr/local/bundle/
