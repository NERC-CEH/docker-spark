FROM nerc/spark-core:2.1.0.2

LABEL maintainer "gareth.lloyd@stfc.ac.uk"

ENV SPARK_USER datalab
ENV SPARK_UID 1000

USER root

# Spark variables
ENV PATH $PATH:/opt/spark/bin
ENV SPARK_NO_DAEMONIZE 1

# Add datalab user
RUN R_LIB_SITE_FIXED=$(R --slave -e "write(gsub('%v', R.version\$minor,Sys.getenv('R_LIBS_SITE')), stdout())") && \
	useradd -m -s /bin/bash -N -u $SPARK_UID $SPARK_USER && \
    chown -R $SPARK_USER $SPARK_HOME && \
    chown -R $SPARK_USER $R_LIB_SITE_FIXED

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
