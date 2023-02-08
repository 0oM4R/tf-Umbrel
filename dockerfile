FROM getumbrel/tor:0.4.7.8@sha256:2ace83f22501f58857fa9b403009f595137fa2e7986c4fda79d82a8119072b6a
FROM nginx:1.17.8@sha256:380eb808e2a3b0dd954f92c1cae2f845e6558a15037efefcabc5b4e03d666d03
FROM getumbrel/dashboard:v0.5.8@sha256:9cfb822da25eee75ed0d74525b7864e0068b1f21edde5ad1c01c9347d24b34b1
FROM getumbrel/manager:v0.5.3@sha256:69caf866f5eb471789726a4584c5dd74eabc34e4b31ca5c846ad26424a7eb534
FROM getumbrel/auth-server:v0.5.1@sha256:afcd9065eab02f98ee6bf705045170a4b385fb5f81e3b168bb92ffb8ac7a1760
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    UMBREL_VERSION="release" \
    UMBREL_REPO="getumbrel/umbrel" \
    UMBREL_INSTALL_PATH="/umbrel" 
RUN apt update && \
    apt -y install wget curl vim net-tools iputils-ping openssh-server docker.io \
    fswatch jq rsync sudo iproute2 git gettext-base python3 gnupg avahi-daemon avahi-discover libnss-mdns nginx
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN mkdir -p ${UMBREL_INSTALL_PATH}
RUN usermod -aG sudo root

RUN  version=$(get_umbrel_version); \
    curl --location "https://api.github.com/repos/${UMBREL_REPO}/tarball/${version}" | \
    tar --extract --gzip --strip-components=1 --directory="${UMBREL_INSTALL_PATH}"


RUN wget -O /sbin/zinit https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit && \
    chmod +x /sbin/zinit

COPY nginx/* /etc/nginx/conf.d/
RUN  rm -rf /etc/nginx/sites-*

RUN mkdir -p /etc/zinit
COPY zinit /etc/zinit
COPY ./yq.sh /
ENTRYPOINT [ "/sbin/zinit", "init" ]