FROM visie/debian
MAINTAINER Evandro Franco de Oliveira Rui <evandro@visie.com.br>
EXPOSE 3306
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
RUN rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/log/mysql.*
RUN mkdir -p /var/log/mysql /var/run/mysqld
RUN ln -sf /dev/stderr -T /var/log/mysql/error.log
COPY usr /usr
COPY etc /etc
