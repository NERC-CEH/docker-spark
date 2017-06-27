FROM nerc/spark-core

LABEL maintainer "gareth.lloyd@stfc.ac.uk"

ENV SPARK_VER 2.1.0
ENV HADOOP_VER 2.7
ENV SPARK_HOME /opt/spark

RUN mkdir -p /opt

RUN wget -O /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz https://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
	tar -zxvf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
	rm -rf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
	mv /spark-${SPARK_VER}-bin-hadoop${HADOOP_VER} ${SPARK_HOME}

ADD start.sh /usr/local/bin

ENV PATH $PATH:/opt/spark/bin
ENV SPARK_NO_DAEMONIZE 1

# Patch SparkR to fix issue -- https://issues.apache.org/jira/browse/SPARK-21093
ADD daemon.R.patch /opt/spark/R/lib/SparkR/worker
RUN patch -b /opt/spark/R/lib/SparkR/worker/daemon.R /opt/spark/R/lib/SparkR/worker/daemon.R.patch

# # Expose ports for monitoring.
# # SparkContext web UI on 4040 -- only available for the duration of the application.
# # Spark master’s web UI on 8080.
# # Spark worker web UI on 8081.
EXPOSE 4040 7077 8080 8081

CMD ["/usr/local/bin/start.sh"]
