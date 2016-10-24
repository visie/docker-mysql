#!/usr/bin/env sh

set -e

# Comando a ser executado
cmd="mysqld"
if [ $(echo ${1} | grep -P '^[^-]') ]; then
    cmd=${1}
    shift
fi

# Se não formos root, apenas executa o comando desejado
test "root" = "$(whoami 2>/dev/null)" || exec ${cmd} ${@}


# Obtém o nome do usuário
test ${USERNAME} || USERNAME=${USER}
test ${USERNAME} || USERNAME=mysql

if [ $(echo ${UID} | grep -P -v '^\d+(:\d+)?$') ]; then
    # UID na verdade é USERNAME
    USERNAME=${UID}
    UID=
    GID=
fi

if [ $(echo ${UID} | grep -P '^\d+:\d+$') ]; then
    # UID contém o GID
    GID=$(echo ${UID} | cut -f2 -d':')
    UID=$(echo ${UID} | cut -f1 -d':')
fi

test ${UID} || UID=$(getent passwd "${USERNAME}" | cut -f3 -d':')
test ${UID} || UID=$(id -u mysql)
test ${GID} || GID=$(getent passwd "${USERNAME}" | cut -f4 -d':')
test ${GID} || GID=$(uid -g mysql)

if [ -z "$(grep -P "${USERNAME}:[^:]*:${UID}:${GID}" /etc/passwd)" ]; then
    # O usuário desejado não existe!
    groupadd -f -g ${GID} -o ${USERNAME}
    useradd -g ${GID} -M -N -o -u ${UID} ${USERNAME}
fi

groupmod -g ${GID} -o ${USERNAME}
usermod -g ${GID} -o -u ${UID} -d /var/lib/mysql -s /usr/bin/mysql ${USERNAME} 2>/dev/null

# Setup inicial das bases e usuários
HOME=$(getent passwd ${USERNAME} | awk -F':' '{print $(NF - 1)}')
test ${HOME} || HOME=/var/lib/mysql
if [ -e ${HOME} ]; then
    test -d ${HOME} || rm -rf ${HOME}
    test -d ${HOME} || mkdir -p ${HOME}
fi

test -n "$(ls ${HOME} 2>/dev/null)" || mysql_install_db ${@} >/dev/null
mysqld ${@} --log-warnings=0 2>/dev/null &
while true; do mysql -e 'exit' 2>/dev/null && break || sleep 1; done

mysql_command () {
    mysql -e "${1}" 2>/dev/null || true
}

mysql_command "create user 'root'@'%' identified by '${MYSQL_ROOT_PASSWORD}';"
mysql_command "grant all privileges on $(echo '*.*') to 'root'@'%' with grant option;"

test -z "${MYSQL_USER}" || mysql_command "create user '${MYSQL_USER}'@'%' identified by '${MYSQL_PASSWORD}';"
test -z "${MYSQL_DATABASE}" || mysql_command "create database '${MYSQL_DATABASE}';"
test -z "${MYSQL_USER}${MYSQL_DATABASE}" || mysql_command "grant all privileges on '${MYSQL_DATABASE}'.* to '${MYSQL_USER}'@'%' with grant option;"

get_mysql_pid () {
    ps ax -opid,command | grep mysqld | awk '{print $1}'
}

while [ "$(get_mysql_pid | wc -l)" != "1" ]; do kill $(get_mysql_pid) 2>/dev/null || sleep 1; done
chown -R ${UID}:${GID} ${HOME}

test "${cmd}" != "mysqld" || cmd="mysqld_safe"
exec ${cmd} ${@}
