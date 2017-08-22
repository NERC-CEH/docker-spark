#!/bin/bash

unset SPARK_MASTER_PORT

if [ "$SPARK_ROLE" = "MASTER" ]; then
  echo "MASTER Node"
  /opt/spark/sbin/start-master.sh --ip spark-master --port 7077
else
  echo "WORKER Node"
  /opt/spark/sbin/start-slave.sh spark://spark-master:7077
fi
