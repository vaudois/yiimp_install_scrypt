#!/bin/bash

source /etc/serveryiimp.conf

PHP_CLI='php -d max_execution_time=60'

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#cd ${DIR}

cd ${STORAGE_SITE}/

date
echo started in ${STORAGE_SITE}

while true; do
        ${PHP_CLI} runconsole.php cronjob/runBlocks
        sleep 20
done
exec bash
