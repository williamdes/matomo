#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PHP_VERSION:-}" ]]; then
  echo "PHP_VERSION is not set; skipping JIT disable."
  exit 0
fi

JIT_INI_CONTENT=$'opcache.jit=0\nopcache.jit_buffer_size=0\n'

echo "Disabling JIT for PHP ${PHP_VERSION}."

CLI_INI_PATH="$(php -i | awk -F'=> ' '/Loaded Configuration File/{print $2; exit}' | xargs)"
if [[ -n "$CLI_INI_PATH" && -f "$CLI_INI_PATH" ]]; then
  sudo cp "$CLI_INI_PATH" "${CLI_INI_PATH}.bak"
  sudo sed -i -E 's/^[; ]*opcache\\.jit\\s*=.*/opcache.jit=0/' "$CLI_INI_PATH"
  if ! grep -q '^opcache.jit=' "$CLI_INI_PATH"; then
    echo "opcache.jit=0" | sudo tee -a "$CLI_INI_PATH" >/dev/null
  fi
  sudo sed -i -E 's/^[; ]*opcache\\.jit_buffer_size\\s*=.*/opcache.jit_buffer_size=0/' "$CLI_INI_PATH"
  if ! grep -q '^opcache.jit_buffer_size=' "$CLI_INI_PATH"; then
    echo "opcache.jit_buffer_size=0" | sudo tee -a "$CLI_INI_PATH" >/dev/null
  fi
else
  echo "Could not locate CLI php.ini via php -i; skipping direct edit."
fi

CLI_INI_DIR="/etc/php/${PHP_VERSION}/cli/conf.d"
FPM_INI_DIR="/etc/php/${PHP_VERSION}/fpm/conf.d"

if [[ -d "$CLI_INI_DIR" ]]; then
  echo "$JIT_INI_CONTENT" | sudo tee "${CLI_INI_DIR}/99-disable-jit.ini" >/dev/null
fi

if [[ -d "$FPM_INI_DIR" ]]; then
  echo "$JIT_INI_CONTENT" | sudo tee "${FPM_INI_DIR}/99-disable-jit.ini" >/dev/null
  sudo systemctl restart "php${PHP_VERSION}-fpm.service" || true
fi

echo "JIT settings after update:"
php -i | awk -F'=> ' '/^opcache\\.jit =>|^opcache\\.jit_buffer_size =>|^JIT =>/{print $1 \" => \" $2}' || true
