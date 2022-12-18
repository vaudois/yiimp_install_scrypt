#!/bin/bash

source /etc/serveryiimp.conf

PHP_CLI='php -d max_execution_time=120'

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#cd ${DIR}

cd ${STORAGE_SITE}/

date
echo started in ${STORAGE_SITE}

while true; do
        ${PHP_CLI} runconsole.php cronjob/run
        sleep 90
done
exec bash
