#!/usr/bin/env bash

set -ex

export PATH=/usr/lib/postgresql/11/bin:$PATH
PGPORT=54321
initdb db1 &>/dev/null

if [[ ! -f postgresql.conf ]]; then
    cp ../../postgresql.conf db1/
else
    cp postgresql.conf db1/
fi

mkdir -p logs
pg_ctl -l logs/logfile_$(date +%Y-%m-%d_%H_%M_%S).log -w -D db1/ start

CONNSTR=$(cat connstr.conf)

pgbench "$CONNSTR" -q -i -s 100
