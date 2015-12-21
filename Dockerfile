FROM debian:wheezy
MAINTAINER Bruno Binet <bruno.binet@gmail.com>
 
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl ca-certificates

ENV INFLUXDB_VERSION 0.8.9

# Install InfluxDB
RUN curl -s -o /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb http://get.influxdb.org.s3.amazonaws.com/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

ADD config.toml /config/config.toml
ADD run.sh /run.sh
RUN chmod +x /*.sh

ENV ROOT_PASSWORD **ChangeMe**
# ENV PRE_CREATE_DB db1;db2;db3
# ENV PRE_CREATE_DBUSER_db1 user1;user2
# ENV db1_user1_PASSWORD mypass
# ENV db1_user1_ADMIN true

# Admin server
EXPOSE 8083

# HTTP API
EXPOSE 8086

# HTTPS API
#EXPOSE 8084

# Raft port (for clustering, don't expose publicly!)
#EXPOSE 8090

# Protobuf port (for clustering, don't expose publicly!)
#EXPOSE 8099

VOLUME ["/data"]

CMD ["/run.sh"]
