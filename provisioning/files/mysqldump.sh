#!/bin/bash

set -euo pipefail

TODAY="$(/bin/date +%d-%m-%Y)"
FILENAME="${TODAY}_mysqldump.sql"

/usr/bin/mysqldump -h localhost -u root --all-databases > "/var/backups/mysql/${FILENAME}"
