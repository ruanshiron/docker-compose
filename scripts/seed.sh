#!/bin/bash
set -e

waitTime=5
dbContainer=db
dbName=dhis2
dbUser=dhis
dbPass=dhis

if [ $# -eq 0 ]
  then
    echo "USAGE: scripts/seed.sh <path/to/seedfile.sql[.gz]>" 1>&2
    exit 1
fi

file="$1"
if [ ! -f $file ]
  then
    echo "ERROR: The file '$file' does not exist." 1>&2
    exit 1
fi

started=0
if [ ${file: -4} == ".sql" ] || [ ${file: -7} == ".sql.gz" ]
  then
    upcount=`docker-compose ps db | grep Up | wc -l`
    if [ $upcount -eq 0 ]
      then
        echo "Starting db container..."
        docker-compose up -d db
        
        echo "Waiting $waitTime seconds for postgres initialization..."
        sleep $waitTime

        started=1
    fi
    
    echo "Importing '$file'..."
    if [ ${file: -7} == ".sql.gz" ]
      then
        gunzip -c $file | docker-compose exec -e PGPASSWORD=$dbPass -T $dbContainer psql -h $dbContainer --dbname $dbName --username $dbUser
      else
        cat $file | docker-compose exec -e PGPASSWORD=$dbPass -T $dbContainer psql -h $dbContainer --dbname $dbName --username $dbUser
    fi
    
    if [ $started -eq 1 ]
      then
        echo "Stopping db container..."
        docker-compose stop db
    fi

    exit 0
  else
    echo "ERROR: Unrecognized file extension, '.sql' or '.sql.gz' expected." 1>&2
    exit 1
fi