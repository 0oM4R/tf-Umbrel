# grid3_Umbrel

Get Umbrel up and running on grid3.

This image based on Debian.

## What in this image

- [Umbrel](https://github.com/getumbrel/umbrel)
- Docker
- Docker-compose
- include preinstalled Nginx, openssh-client, yq, openssh-server, curl, wget, iproute2, python3 and some other packages.
- ufw with restricted rules applied.
- [zinit](https://github.com/threefoldtech/zinit) process manager which is configured with these services:

  - **sshd**: starting OpenSSH server daemon
  - **ssh_config**: Add the user SSH key to authorized_keys, so he can log in remotely to the host which running this image.

  - **ufw-init**: define restricted firewall/iptables rules.
  - **ufw**: apply the pre-defined firewall rules
  > Docker edits iptables directly to setup port forwarding rules so it'll bypass any ufw rules we add, but we add it to close the ports that Docker does not use.
  - **nginx**: run Nginx on port 88, to forward traffic to waiting page if the Umbrel is not ready.
  - **dockerd**: run docker daemon
  - **register**: try to register with user credentials, if the curl returns `No route to host` it will sleep for 5 seconds and try again.
  - **config**: run [Umbrel configuration script](https://github.com/getumbrel/umbrel/blob/master/scripts/configure)
  - **Umbrel**: start Umbrel by running [Umbrel start script](https://github.com/getumbrel/umbrel/blob/master/scripts/start)
    > We manipulate this script by running `sed` command to make the docker-compose running without `--detach` flag.

## Building

in the umbrel directory

`docker build -t {user|org}/grid3_umbrel_docker:latest .`

## Deploying on grid 3

### convert the docker image to Zero-OS flist

Easiest way to convert the docker image to Flist is using [Docker Hub Converter tool](https://hub.grid.tf/docker-convert), make sure you already built and pushed the docker image to docker hub before using this tool.

### Deploying

Easiest way to deploy a VM using the flist is to head to to our [playground](https://play.grid.tf) and deploy a Virtual Machine by providing this flist URL.

> make sure to provide the correct entrypoint, and required env vars.

or use the dedicated Umbrel weblet if available, which will deploy an instance that satisfies the above perquisites.

> TODO: add terraform example file

## Flist

### URL

````
https://hub.grid.tf/kassem.3bot/0om4r-umbrel-0.0.2.flist
````

> TODO: should be updated to official repo.

### Entrypoint

- `/sbin/zinit init`

### Required Env Vars

- `SSH_KEY`: User SSH public key.
- `USERNAME`: this will be used in registration to Umbrel dashboard.
- `PASSWORD`: this will be used in registration, and login to Umbrel dashboard.

### Optional Env Vars

This envs will be used to configure the installation process, and here are its default values.

- `UMBREL_VERSION: "release"`
- `UMBREL_REPO: "getumbrel/umbrel"`
- `UMBREL_INSTALL_PATH: "/umbrel"`

For advanced configuration, please check the envs mentioned in [umbrel-dashboard](https://github.com/getumbrel/umbrel-dashboard), [umbrel-manager](https://github.com/getumbrel/umbrel-manager), and [.env-example](https://github.com/getumbrel/umbrel/blob/master/templates/.env-sample) file.
