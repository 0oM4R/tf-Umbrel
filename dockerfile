FROM debian:stable-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive\
    apt-get -qq install curl net-tools iputils-ping openssh-server docker.io \
    fswatch jq rsync sudo iproute2 git gettext-base python3 gnupg avahi-daemon avahi-discover libnss-mdns \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose


COPY ./scripts /scripts
COPY ./templates /templates
RUN chmod -R +x /scripts; 
RUN /bin/bash -c  "/scripts/yq.sh;"



RUN curl --location  https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit -o /sbin/zinit && \
    chmod +x /sbin/zinit

RUN mkdir -p /etc/zinit;
COPY zinit /etc/zinit
ENTRYPOINT [ "/sbin/zinit", "init" ]