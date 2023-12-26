#!/bin/sh

set -e

# Eclipse Temurin installation on Debian or Ubuntu.
# Ensure the necessary packages are present.
apt install -y wget apt-transport-https

# Download the Eclipse Adoptium GPG key.
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null

# Configure the Eclipse Adoptium apt repository.
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

# Install the Temurin version you require.
apt update -y
apt install temurin-17-jdk

