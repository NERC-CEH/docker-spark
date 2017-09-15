#!/bin/bash
# Modified from the jupyter base-notebook start.sh script
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/start.sh

set -e

# If root user
if [ $(id -u) == 0 ] ; then
  # Alter host file for Spark Master
  ROLE="${SPARK_ROLE:?Must be set to MASTER or WORKER}"
  if [ ${ROLE} = "MASTER" ]; then
    echo "Setting localhost to spark-master"
    echo "$(hostname -i) spark-master" >> /etc/hosts
  fi

  # Only the username "datalab" was created in docker build, 
  # therefore rename "datalab" to $SPARK_USER
  usermod -d /home/$SPARK_USER -l $SPARK_USER datalab

  # Change UID of SPARK_USER to SPARK_UID if it does not match.
  if [ "$SPARK_UID" != $(id -u $SPARK_USER) ] ; then
    echo "Set user UID to: $SPARK_UID"
    usermod -u $SPARK_UID $SPARK_USER

    # R_LIBS_SITE path has contains R version which need to be to be set by R.
    R_LIBS_SITE_FIXED=$(R --slave -e "write(gsub('%v', R.version\$minor,Sys.getenv('R_LIBS_SITE')), stdout())")

    # Fix permissions for home and spark directories
    for d in "$SPARK_HOME" "$R_LIBS_SITE_FIXED" "/home/$SPARK_USER"; do
      if [[ ! -z "$d" && -d "$d" ]]; then
        echo "Set ownership to uid $SPARK_UID: $d"
        chown -R $SPARK_UID "$d"
      fi
    done
  fi

  # Change GID of SPARK_USER to SPARK_GID, if given.
  if [ "$SPARK_GID" ] ; then
    echo "Change GID to $SPARK_GID"
    groupmod -g $SPARK_GID -o $(id -g -n $SPARK_USER)
  fi

  # Exec spark docker-entrypoint as $SPARK_USER
  echo "Execute the command as $SPARK_USER"
  exec su $SPARK_USER -c "env PATH=$PATH $*"
else
  if [[ ! -z "$SPARK_UID" && "$SPARK_UID" != "$(id -u)" ]]; then
    echo 'Container must be run as root to set $SPARK_UID'
  fi
  if [[ ! -z "$SPARK_GID" && "$SPARK_GID" != "$(id -g)" ]]; then
    echo 'Container must be run as root to set $SPARK_GID'
  fi
  echo "This container needs to be run as the root user to allow configuration prior to starting Spark."
  echo "Use '--user root' flag for Docker or set the securityContext annotation for Kubernetes."
  exit 1
fi
