#!/usr/bin/env bash

# if you want to customize specific testset's execution create an "override" command.sh file in testsets folder

set -ex

CONNSTR=$(cat connstr.conf)
/usr/lib/postgresql/11/bin/pgbench "$CONNSTR" -T 1800 -c 16 -M prepared --random-seed=5432