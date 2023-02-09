  #!/usr/bin/env bash
  set -euox pipefail
  declare -A yq_sha256;
  yq_sha256["arm64"]="8879e61c0b3b70908160535ea358ec67989ac4435435510e1fcb2eda5d74a0e9";
  yq_sha256["amd64"]="c93a696e13d3076e473c3a43c06fdb98fafd30dc2f43bc771c4917531961c760";

  yq_version="v4.24.5";
  system_arch=$(dpkg --print-architecture);
  yq_binary="yq_linux_${system_arch}";

  # config sudo 
  usermod -aG sudo root;
  # Download yq from GitHub
  yq_temp_file="/tmp/yq";
  curl -L "https://github.com/mikefarah/yq/releases/download/${yq_version}/${yq_binary}" -o "${yq_temp_file}";

  # Check file matches checksum
  if [[ "$(sha256sum "${yq_temp_file}" | awk '{ print $1 }')" == "${yq_sha256[$system_arch]}" ]]; then
    sudo mv "${yq_temp_file}" /usr/bin/yq;
    sudo chmod +x /usr/bin/yq;

    echo "yq installed successfully..."
  else
    echo "yq install failed. sha256sum mismatch"
    exit 1
  fi