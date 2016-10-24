FROM visie/debian
MAINTAINER Evandro Franco de Oliveira Rui <evandro@visie.com.br>
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y mysql-server
RUN rm -rf /etc/mysql /var/lib/mysql /var/log/mysql.*
RUN rm -rf /var/log/mysql && mkdir -p /var/log/mysql
RUN ln -sf /dev/stdout -T /var/log/mysql/error.log
COPY entrypoint.sh /
COPY mysql /etc/mysql
EXPOSE 3306
