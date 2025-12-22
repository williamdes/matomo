#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PHP_VERSION:-}" ]]; then
  echo "PHP_VERSION is not set; skipping JIT disable."
  exit 0
fi

JIT_INI_CONTENT=$'opcache.jit=0\nopcache.jit_buffer_size=0\n'

CLI_INI_DIR="/etc/php/${PHP_VERSION}/cli/conf.d"
FPM_INI_DIR="/etc/php/${PHP_VERSION}/fpm/conf.d"

echo "Disabling JIT for PHP ${PHP_VERSION} (CLI and FPM)."

if [[ -d "$CLI_INI_DIR" ]]; then
  echo "$JIT_INI_CONTENT" | sudo tee "${CLI_INI_DIR}/99-disable-jit.ini" >/dev/null
fi

if [[ -d "$FPM_INI_DIR" ]]; then
  echo "$JIT_INI_CONTENT" | sudo tee "${FPM_INI_DIR}/99-disable-jit.ini" >/dev/null
  sudo systemctl restart "php${PHP_VERSION}-fpm.service" || true
fi
