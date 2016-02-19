docker-influxdb
===============

InfluxDB docker container.


Build
-----

To create the image `bbinet/influxdb`, execute the following command in the
`docker-influxdb` folder:

    docker build -t bbinet/influxdb .

You can now push the new image to the public registry:
    
    docker push bbinet/influxdb


Configure and run
-----------------

You can configure the InfluxDB running container with some environment
variables, see below.

Required:

- `ROOT_PASSWORD`: the password that must be set for the root admin user.

Optional:

- `PRE_CREATE_DB`: the list of the databases to create automatically at startup
  (example: `PRE_CREATE_DB="db1;db2;db3"`)
- `PRE_CREATE_USER`: the list of users to create automatically at startup
  (example: `PRE_CREATE_USER="user1;user2"`)
- `<user>_PASSWORD`: the password of the user to create for the above database
  (example: `user1_PASSWORD="mypass"`)
- `<user>_ADMIN`: ["true" or "false"] whether the user to create should be
  granted admin rights (example: `user1_ADMIN=true`)
- `<db>_<user>_GRANT`: ["READ", "WRITE", or "ALL"] whether the user should be
  granted read/write privileges to a database (example: `db1_user1_GRANT=ALL`)

Then when starting your InfluxDB container, you will want to bind ports `8083`
and `8086` from the InfluxDB container to the host external ports.
InfluxDB container will write its `db`, `raft`, and `wal` data dirs to the
`/var/lib/influxdb` directory, so you may want to bind this directory to a data
volume or a host directory.

For example:

    $ docker pull bbinet/influxdb

    $ docker run --name influxdb \
          -v $(pwd)/data:/var/lib/influxdb \
          -v $(pwd)/influxdb.conf:/etc/influxdb/influxdb.conf \
          -p 8083:8083 -p 8086:8086 \
          -e ROOT_PASSWORD=root_password \
          -e PRE_CREATE_DB="db1;db2;db3" \
          -e PRE_CREATE_USER="user1;user2" \
          -e user1_PASSWORD="mypass" \
          -e user1_ADMIN="true" \
          -e db1_user2_GRANT="all" \
          bbinet/influxdb
