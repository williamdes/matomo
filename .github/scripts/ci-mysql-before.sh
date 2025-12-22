#!/usr/bin/env bash
set -euo pipefail

HOST="127.0.0.1"
PORT="3306"

mkdir -p matomo/ci-diagnostics

echo "Waiting for MySQL on ${HOST}:${PORT}..."
for i in $(seq 1 30); do
  if mysqladmin ping -h"${HOST}" -uroot --silent; then
    break
  fi
  sleep 1
done

if ! mysqladmin ping -h"${HOST}" -uroot --silent; then
  echo "MySQL not reachable; skipping pre-test diagnostics."
  exit 0
fi

mysql -h"${HOST}" -uroot -e "SET GLOBAL log_output = 'TABLE';"
mysql -h"${HOST}" -uroot -e "SET GLOBAL slow_query_log = 'ON';"
mysql -h"${HOST}" -uroot -e "SET GLOBAL long_query_time = 0.5;"
mysql -h"${HOST}" -uroot -e "SHOW VARIABLES LIKE 'slow_query_log%';" > matomo/ci-diagnostics/mysql-slow-log-vars.txt
mysql -h"${HOST}" -uroot -e "SHOW VARIABLES LIKE 'long_query_time';" >> matomo/ci-diagnostics/mysql-slow-log-vars.txt
mysql -h"${HOST}" -uroot -e "SHOW VARIABLES LIKE 'log_output';" >> matomo/ci-diagnostics/mysql-slow-log-vars.txt

mysql -h"${HOST}" -uroot -e "SHOW GLOBAL STATUS" > matomo/ci-diagnostics/mysql-status-before.txt
mysql -h"${HOST}" -uroot -e "SHOW ENGINE INNODB STATUS\\G" > matomo/ci-diagnostics/innodb-status-before.txt
mysql -h"${HOST}" -uroot -e "SHOW PROCESSLIST" > matomo/ci-diagnostics/processlist-before.txt

echo "date: $(date -u +%FT%TZ)" > matomo/ci-diagnostics/system-before.txt
echo "uname: $(uname -a)" >> matomo/ci-diagnostics/system-before.txt
free -m >> matomo/ci-diagnostics/system-before.txt
df -h >> matomo/ci-diagnostics/system-before.txt
vmstat 1 5 >> matomo/ci-diagnostics/system-before.txt
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 25 >> matomo/ci-diagnostics/system-before.txt
