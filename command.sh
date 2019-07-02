#!/usr/bin/env bash

# if you want to customize specific testset's execution create an "override" command.sh file in testsets folder

set -ex

CONNSTR=$(cat connstr.conf)
pgbench "$CONNSTR" -T1 -c1 postgres
