FROM debian:jessie
MAINTAINER Bruno Binet <bruno.binet@gmail.com>
 
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl ca-certificates

ENV INFLUXDB_VERSION 0.10.1-1
ENV INFLUXDB_MD5 59a0dad806b057f7910a59208a2b385f

# Install InfluxDB
RUN curl -s -o /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  echo "${INFLUXDB_MD5}  /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb" | md5sum --check && \
  dpkg -i /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

# Activate auth-enabled in influxdb config file
RUN sed -i "s/^\( *auth-enabled *=\).*$/\1 true/" /etc/influxdb/influxdb.conf
ADD run.sh /run.sh
RUN chmod +x /*.sh

ENV ROOT_PASSWORD **ChangeMe**
# ENV PRE_CREATE_DB db1;db2;db3
# ENV PRE_CREATE_USER_db1 user1;user2
# ENV user1_PASSWORD mypass
# ENV user1_ADMIN true
# ENV db1_user1_GRANT all

# Admin server
EXPOSE 8083

# HTTP API
EXPOSE 8086

CMD ["/run.sh"]
