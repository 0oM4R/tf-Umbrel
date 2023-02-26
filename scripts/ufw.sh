#!/bin/bash

set -x

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw limit ssh