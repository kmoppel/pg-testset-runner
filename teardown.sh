#!/usr/bin/env bash

set -ex

pg_ctl -D db1/ -w stop
rm -rf db1

