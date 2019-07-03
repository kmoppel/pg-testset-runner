#!/usr/bin/env bash

set -ex

# Specified DB will be used for storing pg_stat_statement snapshots for all testsets. must exists already
PGHOST=/var/run/postgresql
PGPORT=5432
PGUSER=postgres
PGDATABASE=postgres

PSQL=/usr/lib/postgresql/11/bin/psql
DELETE_OLD_RESULTS=1

DO_SETUP=1
DO_TEARDOWN=1

LOOPS=1

# Initialize the table for storing pg_stat_statement results
$PSQL -qXc "create table if not exists pg_testset_runner_results as select ''::text as testset, 0 as loop, now() as created_on, * from pg_stat_statements where false"
if [ $DELETE_OLD_RESULTS -gt 0 ]; then
    echo "Removing previous test results..."
    $PSQL -qc "truncate table pg_testset_runner_results"
fi

# exit 0

TESTSETS=$(find ./testsets/ -maxdepth 1 -type d -exec basename {} \; | grep -vE '^testsets$' | grep -vE '_off_')

# some basic validation
if [ -z "$TESTSETS" ]; then
    echo "No testset subfolders found from 'testsets' folders"
    exit 1
fi

START_TIME=$(date +%s)

# Main loop

for LOOP in $(seq 1 ${LOOPS}) ; do

echo "Starting loop $loop ..."

# Test conn and do pg_stat_statement and pgbench setup
for CURSET in ${TESTSETS} ; do
    CURSET_NAME=$(echo $CURSET | sed 's#^[0-9]*\_\(.*\)#\1#g')
    echo "Processing testset ${CURSET_NAME} from folder ${CURSET}..."

    if [ -f "testsets/${CURSET}/setup.sh" ] ; then
        echo "Calling custom setup.sh for testset ${CURSET}"
        pushd "testsets/${CURSET}"
        ./setup.sh
        popd
    else
        echo "Calling global setup.sh for testset ${CURSET}"
        ./setup.sh
    fi
    echo "Done. Retcode $?"

    CONN_STR=
    if [ -f "testsets/${CURSET}/connstr.conf" ]; then
        CONN_STR=$(cat "testsets/${CURSET}/connstr.conf")
    else
        CONN_STR=$(cat connstr.conf)
    fi
    if [ -z "$CONN_STR" ] ; then
        echo "Could not determine connect string for ${CURSET}, check connstr.conf file. exiting..."
        exit 1
    fi

    echo "Setting up pg_stat_statements on ${CONN_STR}..."
    $PSQL ${CONN_STR} -qXc "create extension if not exists pg_stat_statements"
    $PSQL ${CONN_STR} -qXc "select pg_stat_statements_reset()"
    $PSQL ${CONN_STR} -qXc "checkpoint"



    if [ -f "testsets/${CURSET}/command.sh" ] ; then
        echo "Calling test command 'testsets/${CURSET}/setup.sh'"
        ./testsets/${CURSET}/command.sh
    else
        echo "Calling global test command..."
        ./command.sh
    fi
    echo "Done. Retcode $?"

    # Store results for this run
    echo "Storing pg_stat_statements results for ${CURSET}..."
    $PSQL "${CONN_STR}" -qXc "copy (select '${CURSET_NAME}', '${LOOP}', now(), * from pg_stat_statements where dbid = (select oid from pg_database where datname=current_database())) to stdout" \
        | $PSQL -qXc "copy pg_testset_runner_results from stdin"

    if [ ! $? -eq 0 ]; then
        echo "Could not store pg_stat_statement contents. exit"
        exit 1
    fi


    if [ -f "testsets/${CURSET}/setup.sh" ] ; then
        echo "Calling custom teardown.sh for testset ${CURSET}"
        pushd "testsets/${CURSET}"
        ./teardown.sh
        popd
    else
        echo "Calling global teardown.sh for testset ${CURSET}"
        ./teardown.sh
    fi
    echo "Done. Retcode $?"

done

echo "Finished loop $LOOP"

done

END_TIME=$(date +%s)
TIME_SEC=$((END_TIME- START_TIME))
echo "Done. Finished in $TIME_SEC seconds"
