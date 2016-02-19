#!/bin/bash

set -m


abort() {
    msg="$1"
    echo "$msg"
    echo "=> Environment was:"
    env
    echo "=> Program terminated!"
    exit 1
}

check_update_root_password() {
    # try to create the 'root' admin user
    influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} \
        -execute="CREATE USER root WITH PASSWORD '${ROOT_PASSWORD}' WITH ALL PRIVILEGES" \
         > /dev/null 2>&1 || echo "=> Admin user 'root' already exists."
    # check if the given root password is valid
    influx_exec "SHOW DATABASES" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "=> Password supplied for InfluxDB root user is ok." 
    else
        abort "=> Password supplied for InfluxDB root user is wrong!"
    fi
}

create_db() {
    db=$1
    influx_exec "CREATE DATABASE $db" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "=> Database \"${db}\" ok."
    else
        abort "=> Failed to create database \"${db}\"!"
    fi
}

create_user() {
    user=$1
    password=$2
    admin=${3:-"false"}
    admin=${admin,,} # convert to lowercase
    if [ -z "${user}" ] || [ -z "${password}" ] ; then
        abort "=> create_user first 2 args are required (user and password)."
    fi
    if [ "${admin}" != "true" ] && [ "${admin}" != "false" ]; then
        abort "=> Wrong value for create_user admin arg: ${admin}."
    fi
    influx_exec "CREATE USER ${user} WITH PASSWORD '${password}'" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "=> User \"${user}\" ok."
    else
        abort "=> Failed to create user \"${user}\"!"
    fi

    # update admin rights
    if [ "${admin}" == "true" ]; then
        influx_exec "GRANT ALL PRIVILEGES TO ${user}" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "=> Grant admin rights to \"${user}\" ok."
        else
            abort "=> Failed to grant admin rights to \"${user}\"!"
        fi
    fi
    # TODO: else REVOKE ALL PRIVILEGES for non admin users?
}

grant() {
    db=$1
    user=$2
    privileges=$3
    privileges=${privileges^^} # convert to uppercase
    if [ -z "${db}" ] || [ -z "${user}" ] || [ -z "${privileges}" ] ; then
        abort "=> grant 3 args are required (db, user and privileges)."
    fi
    if [ "${privileges}" != "READ" ] && [ "${privileges}" != "WRITE" ] && [ "${privileges}" != "ALL" ]; then
        abort "=> Wrong value for grant privileges arg: ${privileges}."
    fi

    influx_exec "GRANT ${privileges} ON ${db} TO ${user}" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "=> Grant ${privileges} on db \"${db}\" to user \"${user}\" ok."
    else
        abort "=> Failed to grant ${privileges} on ${db} to \"${user}\"!"
    fi
}

influx_exec () {
    query=$1
    influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} \
        -username=root -password="${ROOT_PASSWORD}" -execute="${query}"
}

######### MAIN #########

if [ "${ROOT_PASSWORD}" == "**ChangeMe**" ]; then
    abort "=> No password is specified for InfluxDB root user!"
fi

CONFIG_FILE="/etc/influxdb/influxdb.conf"
INFLUX_HOST="localhost"
INFLUX_API_PORT="8086"
API_URL="http://${INFLUX_HOST}:${INFLUX_API_PORT}"

# check that 'auth-enabled' config option is activated
grep "^ *auth-enabled *= *true *$" ${CONFIG_FILE} > /dev/null
if [ $? -ne 0 ]
then
    abort "=> \"auth-enabled\" config option should be set to \"true\"."
fi

# echo "=> InfluxDB configuration: "
# cat ${CONFIG_FILE}
echo "=> Starting InfluxDB..."
exec influxd -config=${CONFIG_FILE} &

echo -n "=> Waiting for InfluxDB to be ready "
ret=1
while [[ ret -ne 0 ]]; do
    echo -n "."
    sleep 3
    curl -k ${API_URL}/ping 2> /dev/null
    ret=$?
done
echo ""

check_update_root_password

if [ -z "${PRE_CREATE_DB}" ]; then
    echo "=> No database names supplied: no database will be created."
else
    for db in $(echo ${PRE_CREATE_DB} | tr ";" "\n"); do
        create_db $db
    done
fi

if [ -z "${PRE_CREATE_USER}" ]; then
    echo "=> No user names supplied: no user will be created."
else
    for user in $(echo ${PRE_CREATE_USER} | tr ";" "\n"); do
        userpassword_var="${user}_PASSWORD"
        useradmin_var="${user}_ADMIN"
        create_user $user ${!userpassword_var} ${!useradmin_var:-"false"}
    done
fi

for db in $(echo ${PRE_CREATE_DB} | tr ";" "\n"); do
    for user in $(echo ${PRE_CREATE_USER} | tr ";" "\n"); do
        grant_var="${db}_${user}_GRANT"
        if [ -n "${!grant_var}" ]; then
            grant $db $user ${!grant_var}
        fi
    done
done

fg
