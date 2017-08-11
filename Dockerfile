FROM nerc/spark-core

LABEL maintainer "gareth.lloyd@stfc.ac.uk"

ENV SPARK_VER 2.1.0
ENV HADOOP_VER 2.7
ENV SPARK_HOME /opt/spark
ENV SPARK_USER datalab
ENV SPARK_UID 1000

USER root

# Install Spark
RUN wget -O /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz https://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    tar -zxvf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    rm -rf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    mv /spark-${SPARK_VER}-bin-hadoop${HADOOP_VER} ${SPARK_HOME}

# Spark variables
ENV PATH $PATH:/opt/spark/bin
ENV SPARK_NO_DAEMONIZE 1

# Add datalab user
RUN useradd -m -s /bin/bash -N -u $SPARK_UID $SPARK_USER &&\
    chown -R $SPARK_USER $SPARK_HOME

# Install Tini
RUN wget -O /tmp/tini https://github.com/krallin/tini/releases/download/v0.15.0/tini && \
    mv /tmp/tini /usr/bin/tini && \
    chmod +x /usr/bin/tini

# Patch SparkR to fix issue -- https://issues.apache.org/jira/browse/SPARK-21093
ADD daemon.R.patch /opt/spark/R/lib/SparkR/worker
RUN patch -b /opt/spark/R/lib/SparkR/worker/daemon.R /opt/spark/R/lib/SparkR/worker/daemon.R.patch

# # Expose ports for monitoring.
# # SparkContext web UI on 4040 -- only available for the duration of the application.
# # Spark master’s web UI on 8080.
# # Spark worker web UI on 8081.
EXPOSE 4040 7077 8080 8081

WORKDIR ${SPARK_HOME}

COPY ./start.sh /usr/local/bin
COPY ./docker-entrypoint.sh /usr/local/bin

ENTRYPOINT ["tini", "--"]
CMD ["start.sh", "docker-entrypoint.sh"]

USER $SPARK_USER
