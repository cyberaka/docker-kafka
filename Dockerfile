FROM openjdk:8-jre-alpine

MAINTAINER Christian González <christiangda@gmail.com>

# Arguments from docker build proccess
ARG SCALA_VERSION
ARG KAFKA_DOWNLOAD_MIRROR
ARG KAFKA_VERSION

# Environment variables
ENV container docker
ENV SCALA_VERSION ${SCALA_VERSION:-2.11}
ENV KAFKA_VERSION ${KAFKA_VERSION:-0.11.0.1}
ENV KAFKA_DOWNLOAD_MIRROR ${KAFKA_DOWNLOAD_MIRROR:-http://apache.mirrors.pair.com}
ENV KAFKA_HOME "/opt/kafka"
ENV PATH $KAFKA_HOME/bin:$PATH

ENV KAFKA__PORT=9092 \
    KAFKA__DATA_PATH="/opt/kafka/data" \
    KAFKA__BROKER_ID=0 \
    KAFKA__NUM_NETWORK_THREADS=3 \
    KAFKA__NUM_IO_THREADS=8 \
    KAFKA__SOCKET_SEND_BUFFER_BYTES=102400 \
    KAFKA__SOCKET_RECEIVE_BUFFER_BYTES=102400 \
    KAFKA__SOCKET_REQUEST_MAX_BYTES=104857600 \
    KAFKA__LOG_DIRS="/opt/kafka/logs" \
    KAFKA__NUM_PARTITIONS=1 \
    KAFKA__NUM_RECOVERY_THREADS_PER_DATA_DIR=1 \
    KAFKA__OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
    KAFKA__TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
    KAFKA__TRANSACTION_STATE_LOG_MIN_ISR=1 \
    KAFKA__LOG_RETENTION_HOURS=168 \
    KAFKA__LOG_SEGMENT_BYTES=1073741824 \
    KAFKA__LOG_RETENTION_CHECK_INTERVAL_MS=300000 \
    KAFKA__ZOOKEEPER_CONNECT="localhost:2181" \
    KAFKA__ZOOKEEPER_CONNECTON_TIMEOUT_MS=6000 \
    KAFKA__GROUP_INITIAL_REBALANCE_DELAY_MS=0 \
    KAFKA__JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.rmi.port=1099"

# Container's Labels
LABEL Description "Apache Kafka docker image" \
      Vendor "Christian González" \
      Name "Apache Kafka" \
      Version ${SCALA_VERSION}-${KAFKA_VERSION}

LABEL Build "docker build --no-cache --rm \
            --build-arg SCALA_VERSION=2.11 \
            --build-arg KAFKA_VERSION=0.11.0.1 \
            --build-arg KAFKA_DOWNLOAD_MIRROR=http://apache.mirrors.pair.com \
            --tag christiangda/kafka:2.11-0.11.0.1 \
            --tag christiangda/kafka:latest \
            --tag christiangda/kafka:canary ." \
      Run "docker run --rm -t -i -h "kafka-01" christiangda/kafka" \
      Connect "docker exec -ti <container id from 'docker ps' command> /bin/bash"

# Create service's user
RUN addgroup -g 1000 kafka \
    && mkdir -p ${KAFKA_HOME} \
    && adduser -u 1000 -S -D -G kafka -h ${KAFKA_HOME} -s /sbin/nologin -g "Kafka user" kafka \
    && chmod 755 ${KAFKA_HOME} \
    && mkdir -p ${KAFKA__LOG_DIRS} \
    && mkdir -p ${KAFKA__DATA_PATH} \
    && chown -R kafka.kafka ${KAFKA_HOME}

RUN apk --no-cache --update add wget bash \
    && wget -q -O - "${KAFKA_DOWNLOAD_MIRROR}"/kafka/"${KAFKA_VERSION}"/kafka_"${SCALA_VERSION}"-"${KAFKA_VERSION}".tgz | tar -xzf - -C ${KAFKA_HOME} --strip 1 \
    && chown -R kafka.kafka /opt \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Exposed ports
EXPOSE ${KAFKA__PORT}

VOLUME ["/opt/kafka/config", "/opt/kafka/logs", "/opt/kafka/data"]

USER kafka

COPY kafka-docker-entrypoint.sh ${KAFKA_HOME}/bin/ \
    && chown -R kafka.kafka /opt

WORKDIR /opt/kafka

# Default command to run on boot
CMD ["bin/kafka-server-start.sh", "config/server.properties"]
