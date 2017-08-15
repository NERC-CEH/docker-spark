#!/bin/bash
# Modified from the jupyter base-notebook start.sh script
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/start.sh

set -e

# If root user
if [ $(id -u) == 0 ] ; then
  # Only the username "datalab" was created in docker build, 
  # therefore rename "datalab" to $SPARK_USER
  usermod -d /home/$SPARK_USER -l $SPARK_USER datalab

  # Change UID of SPARK_USER to SPARK_UID if it does not match.
  if [ "$SPARK_UID" != $(id -u $SPARK_USER) ] ; then
    echo "Set user UID to: $SPARK_UID"
    usermod -u $SPARK_UID $SPARK_USER

    # Fix permissions for home and spark directories
    for d in "$SPARK_HOME" "/home/$SPARK_USER"; do
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
  echo "Execute the command"
  exec $*
fi
