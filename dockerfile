FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    UMBREL_VERSION="release" \
    UMBREL_REPO="getumbrel/umbrel" \
    UMBREL_INSTALL_PATH="$HOME/umbrel" \
    NGINX_PORT=88

RUN apt update && \
    apt -y install wget curl vim net-tools iputils-ping openssh-server docker.io \
    fswatch jq rsync sudo iproute2 git gettext-base python3 gnupg avahi-daemon avahi-discover libnss-mdns nginx ufw

RUN curl -L https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN mkdir -p ${UMBREL_INSTALL_PATH}; \
    mkdir -p /etc/zinit;
COPY ./scripts /scripts
RUN chmod -R +x /scripts; 
RUN /bin/bash -c  "/scripts/yq.sh;"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN version=$(curl --silent https://api.github.com/repos/${UMBREL_REPO}/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\).*/\1/p') \
    curl --location "https://api.github.com/repos/${UMBREL_REPO}/tarball/${version}" | \
    tar --extract --gzip --strip-components=1 --directory="${UMBREL_INSTALL_PATH}"; \
    sed -i  "s/up --detach --build --remove-orphans/pull/" ${UMBREL_INSTALL_PATH}/scripts/start \
    sed -i  "s/.*docker-compose.tor.yml.*/ docker-compose --file docker-compose.tor.yml up --detach --build --remove-orphans;/" ${UMBREL_INSTALL_PATH}/scripts/start;\
    yq -i '.networks.default.enable_ipv6=true' ${UMBREL_INSTALL_PATH}/docker-compose.yml; \
    yq -i '.networks.default.ipam.config +={"subnet":"2001:db8:a::/64", "gateway":"2001:db8:a::1"}' ${UMBREL_INSTALL_PATH}/docker-compose.yml; 


COPY nginx/* /etc/nginx/conf.d/
RUN  rm -rf /etc/nginx/sites-*

RUN curl --location  https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit -o /sbin/zinit && \
    chmod +x /sbin/zinit

COPY zinit /etc/zinit
ENTRYPOINT [ "/sbin/zinit", "init" ]