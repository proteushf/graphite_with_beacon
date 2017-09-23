# installing graphite, reference:
# https://github.com/hopsoft/docker-graphite-statsd/blob/master/Dockerfile
FROM phusion/baseimage:0.9.18
# FROM ubuntu:14.04
MAINTAINER kevinhfzhao@gmail.com

#RUN echo deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main universe > /etc/apt/sources.list.d/universe.list
RUN apt-get -y update && apt-get -y upgrade

# dependencies
RUN apt-get -y --force-yes install vim\
    nginx\
    python-dev\
    python-flup\
    python-pip\
    python-ldap\
     expect\
    git\
    memcached\
    sqlite3\
    libcairo2\
    libcairo2-dev\
    python-cairo\
    pkg-config\
    nodejs\
    supervisor\
    exim4\
    curl

# python dependencies
RUN pip install django==1.5.12\
    python-memcached==1.53\
    django-tagging==0.3.1\
    twisted==11.1.0\
    txAMQP==0.6.2

# install graphite
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web
WORKDIR /usr/local/src/graphite-web
RUN python ./setup.py install
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/
ADD conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py

# install whisper
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/whisper.git /usr/local/src/whisper
WORKDIR /usr/local/src/whisper
RUN python ./setup.py install

# install carbon
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/carbon.git /usr/local/src/carbon
WORKDIR /usr/local/src/carbon
RUN python ./setup.py install

# install statsd
RUN git clone -b v0.7.2 https://github.com/etsy/statsd.git /opt/statsd
ADD conf/opt/statsd/config.js /opt/statsd/config.js

# config nginx
RUN rm /etc/nginx/sites-enabled/default
ADD conf/etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/etc/nginx/sites-enabled/graphite-statsd.conf /etc/nginx/sites-enabled/graphite-statsd.conf

# init django admin
ADD conf/usr/local/bin/django_admin_init.exp /usr/local/bin/django_admin_init.exp
RUN /usr/local/bin/django_admin_init.exp

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx
ADD conf/etc/logrotate.d/graphite-statsd /etc/logrotate.d/graphite-statsd

# daemons
ADD conf/etc/service/carbon/run /etc/service/carbon/run
ADD conf/etc/service/carbon-aggregator/run /etc/service/carbon-aggregator/run
ADD conf/etc/service/graphite/run /etc/service/graphite/run
ADD conf/etc/service/statsd/run /etc/service/statsd/run
ADD conf/etc/service/nginx/run /etc/service/nginx/run

# default conf setup
ADD conf /etc/graphite-statsd/conf
ADD conf/etc/my_init.d/01_conf_init.sh /etc/my_init.d/01_conf_init.sh

# cleanup
RUN apt-get clean\
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# defaults
EXPOSE 80 2003-2004 2023-2024 8125/udp 8126
VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/etc/nginx", "/opt/statsd", "/etc/logrotate.d", "/var/log"]
WORKDIR /
ENV HOME /root

# installing graphite beacon. reference:
# https://github.com/klen/graphite-beacon/blob/develop/Dockerfile
ENV DEBIAN_FRONTEND noninteractive
# COPY external/graphite-beacon /graphite-beacon
# RUN cd /graphite-beacon && python setup.py build && python setup.py install
RUN pip install graphite-beacon
RUN pip install supervisor-stdout

# Supervisord
ADD graphite-beacon/docker/supervisor.conf /etc/supervisor/conf.d/deliverous.conf

# Conf Exim
ADD graphite-beacon/docker/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
ADD graphite-beacon/docker/exim4 /etc/default/exim4

ADD graphite-beacon/config.json /srv/alerting/etc/config.json
RUN echo '{ "include":["/srv/alerting/etc/config.json"] }' > /config.json

# combined graphite and graphite-beacon commands
WORKDIR /
COPY run.sh /run.sh
CMD ["./run.sh"]

