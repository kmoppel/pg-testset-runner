# pg-testset-runner

A simple framework for running a set of arbitrary Postgres test scripts (optionally with varied configs) and storing the results as pg_stat_statements snapshots.

# Test flow

1. Create a subfolder in "testsets" directory for each test unit including optional custom setup, teardown and and actual test script code.
1. The folder name acts as "ID" for the testset so makes sense to make it descriptive. The first substring before an underscore will not count as name and only serves as a numeric sorting column.
1. It's possible to override all or none of the "default" testset setup files - in case not specified the top level "default" is used. All other files (like postgresql.conf) in the folder are ignored unless explicitly used used by setup script for example. Following setup files are used:
  * setup.sh - typically for initializing a new PostgreSQL cluster or restarting it before a test      
  * teardown.sh - typically for stopping a new PostgreSQL cluster and maybe also securing the Postgres logs
  * connstr.conf - used for connecting to instance under testing 
  * command.sh - for actually launching pgbench, custom SQL files or any other program
1. Run the "runsets.sh" from project top folder to start running the testest alphabetically. Running is aborted on first testset error encountered.
1. Tip - include '\_off\_' in a testset's name to disable it