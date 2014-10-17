#!/bin/bash

set -m

if [ "${ROOT_PASSWORD}" == "**ChangeMe**" ]; then
    echo "=> No password is specified for InfluxDB root user!"
    echo "=> Program terminated!"
    exit 1
fi

echo "=> Starting InfluxDB ..."
exec /usr/bin/influxdb -config=/config/config.toml &

#wait for the startup of influxdb
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of InfluxDB service startup ..."
    sleep 3 
    curl -s -o /dev/null http://localhost:8086/ping
    RET=$?
done
echo ""


# check if default root password "root" is still valid
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=root")
if test $STATUS -eq 200; then
    # let's update the root password
    STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins/root?u=root&p=root" -d "{\"password\": \"${ROOT_PASSWORD}\"}")
    if test $STATUS -eq 200; then
        echo "=> InfluxDB root password successfully updated."
    else
        echo "=> Failed to update InfluxDB root password!"
        echo "=> Program terminated!"
        exit 1
    fi
else
    # default root password "root" has already been changed
    # check if the given one is valid:
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=${ROOT_PASSWORD}")
    if test $STATUS -eq 200; then
        echo "=> Password supplied for InfluxDB root user is already ok." 
    else
        echo "=> Password supplied for InfluxDB root user is wrong!"
        echo "=> Program terminated!"
        exit 1
    fi
fi

if [ "${INFLUXDB_DEFAULT_DB_NAME}" == "**None**" ]; then
    echo "=> No default database name supplied: no database will be created."
else
    curl -s "http://localhost:8086/db?u=root&p=${ROOT_PASSWORD}" | grep -q "\"name\":\"${INFLUXDB_DEFAULT_DB_NAME}\""
    if [ $? -eq 0 ]; then
        echo "=> Database \"${INFLUXDB_DEFAULT_DB_NAME}\" already exists: nothing to do."
    else
        echo "=> Creating database: ${INFLUXDB_DEFAULT_DB_NAME}"
        STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/db?u=root&p=${ROOT_PASSWORD}" -d "{\"name\":\"${INFLUXDB_DEFAULT_DB_NAME}\"}")
        if test $STATUS -eq 201; then
            echo "=> Database \"${INFLUXDB_DEFAULT_DB_NAME}\" successfully created."
        else
            echo "=> Failed to create database \"${INFLUXDB_DEFAULT_DB_NAME}\"!"
            echo "=> Program terminated!"
            exit 1
        fi
    fi

    if [ "${INFLUXDB_DEFAULT_DB_USER}" == "**None**" ]; then
        echo "=> No default database user supplied: no user will be created."
    else
        curl -s "http://localhost:8086/db/${INFLUXDB_DEFAULT_DB_NAME}/users?u=root&p=${ROOT_PASSWORD}" | grep -q "\"name\":\"${INFLUXDB_DEFAULT_DB_USER}\""
        if [ $? -eq 0 ]; then
            echo "=> User \"${INFLUXDB_DEFAULT_DB_USER}\" already exists: nothing to do."
        else
            if [ "${INFLUXDB_DEFAULT_DB_PASSWORD}" == "**None**" ]; then
                echo "=> You must specify a password in INFLUXDB_DEFAULT_DB_PASSWORD env variable!"
                echo "=> Program terminated!"
                exit 1
            fi
            echo "=> Creating user: ${INFLUXDB_DEFAULT_DB_USER}"
            STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/db/${INFLUXDB_DEFAULT_DB_NAME}/users?u=root&p=${ROOT_PASSWORD}" -d "{\"name\":\"${INFLUXDB_DEFAULT_DB_USER}\", \"password\":\"${INFLUXDB_DEFAULT_DB_PASSWORD}\"}")
            if test $STATUS -eq 200; then
                echo "=> User \"${INFLUXDB_DEFAULT_DB_USER}\" successfully created."
                STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/db/${INFLUXDB_DEFAULT_DB_NAME}/users/${INFLUXDB_DEFAULT_DB_USER}?u=root&p=${ROOT_PASSWORD}" -d "{\"admin\":true}")
                if test $STATUS -ne 200; then
                    echo "=> Failed to give admin rights to user: ${INFLUXDB_DEFAULT_DB_USER}"
                fi
            else
                echo "=> Failed to create user \"${INFLUXDB_DEFAULT_DB_USER}\"!"
                echo "=> Program terminated!"
                exit 1
            fi
        fi
    fi
fi

fg

