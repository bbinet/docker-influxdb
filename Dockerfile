FROM debian:jessie

MAINTAINER Bruno Binet <bruno.binet@gmail.com>

ENV INFLUXDB_VERSION 1.1.1
ENV INFLUXDB_MD5 ee4147bd0827ad8c3a571924ce546994

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get install -yq --no-install-recommends curl ca-certificates && \
  curl -fSL -o /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  echo "${INFLUXDB_MD5}  /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb" | md5sum --check && \
  dpkg -i /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

# Activate auth-enabled in influxdb config file
RUN sed -i "s/^# \[http\]$/[http]/" /etc/influxdb/influxdb.conf
RUN sed -i "s/\(# *auth-enabled *=\).*$/auth-enabled = true/" /etc/influxdb/influxdb.conf
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
