FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    UMBREL_VERSION="release" \
    UMBREL_REPO="getumbrel/umbrel" \
    UMBREL_INSTALL_PATH="/umbrel" \
    NGINX_PORT=88

RUN apt update && \
    apt -y install wget curl vim net-tools iputils-ping openssh-server docker.io \
    fswatch jq rsync sudo iproute2 git gettext-base python3 gnupg avahi-daemon avahi-discover libnss-mdns nginx ufw

RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN mkdir -p ${UMBREL_INSTALL_PATH}; \
    mkdir -p /etc/zinit;
COPY ./scripts /scripts
RUN chmod -R +x /scripts; 
RUN /bin/bash -c  "/scripts/yq.sh;"


RUN version=$(get_umbrel_version); \
    curl --location "https://api.github.com/repos/${UMBREL_REPO}/tarball/${version}" | \
    tar --extract --gzip --strip-components=1 --directory="${UMBREL_INSTALL_PATH}"; \
    sed --i '/--detach/,${s// /;b};$q1' ${UMBREL_INSTALL_PATH}/scripts/start || echo faild; 


COPY nginx/* /etc/nginx/conf.d/
RUN  rm -rf /etc/nginx/sites-*

RUN wget -O /sbin/zinit https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit && \
    chmod +x /sbin/zinit

COPY zinit /etc/zinit
ENTRYPOINT [ "/sbin/zinit", "init" ]