# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:stretch

ENV APACHE2_HTTP=REDIRECT \
    ICINGA2_FEATURE_GRAPHITE=false \
    ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
    ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
    ICINGA2_FEATURE_GRAPHITE_URL=http://graphite \
    ICINGA2_USER_FULLNAME="Icinga2" \
    ICINGA2_FEATURE_DIRECTOR="true" \
    ICINGA2_FEATURE_DIRECTOR_KICKSTART="true" \
    ICINGA2_FEATURE_DIRECTOR_USER="icinga2-director"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

RUN export DEBIAN_FRONTEND=noninteractive \
     && apt-get update \
     && apt-get upgrade -y \
     && apt-get install -y --no-install-recommends \
          apache2 \
          ca-certificates \
          curl \
          dnsutils \
          gnupg \
          locales \
          lsb-release \
          mailutils \
          mariadb-client \
          mariadb-server \
          php7.0 \
          php-curl \
          php-ldap \
          php-mysql \
          procps \
          pwgen \
          snmp \
          ssmtp \
          sudo \
          supervisor \
          unzip \
          wget \
          git \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* 

RUN export DEBIAN_FRONTEND=noninteractive \
    && cd /usr/share \
    && apt-get update \
    && apt-get install -y cmake build-essential pkg-config libssl-dev libboost-all-dev bison flex \
        libsystemd-dev default-libmysqlclient-dev libpq-dev libyajl-dev libedit-dev \
    && apt-get clean \
    && groupadd icinga \
    && groupadd icingacmd \
    && useradd -c "icinga" -s /sbin/nologin -G icingacmd -g icinga icinga \
    && usermod -a -G icingacmd www-data \
    && git clone https://github.com/Icinga/icinga2.git icinga2 \
    && cd icinga2 \
    && mkdir build && cd build \
    && cmake .. \
    && make \
    && make install

RUN export DEBIAN_FRONTEND=noninteractive \
    && cd /usr/share/ \
    && git clone https://github.com/Icinga/icingaweb2.git icingaweb2 \
    && addgroup --system icingaweb2 \
    && ln -s /usr/share/icingaweb2/bin/icingacli /usr/bin/icingacli \
    && apt-get update && apt-get install -y php-cli php-htmlpurifier

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        monitoring-plugins \
        nagios-nrpe-plugin \
        nagios-snmp-plugins \
        nagios-plugins-contrib \
     && apt-get clean

ARG GITREF_ICINGAWEB2=master
ARG GITREF_DIRECTOR=master
ARG GITREF_MODGRAPHITE=master
ARG GITREF_MODAWS=master

# Temporary hack to get icingaweb2 modules via git
RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2/archive/${GITREF_ICINGAWEB2}.tar.gz" \
    | tar xz --strip-components=2 --directory=/usr/local/share/icingaweb2/modules -f - icingaweb2-${GITREF_ICINGAWEB2}/modules/monitoring icingaweb2-${GITREF_ICINGAWEB2}/modules/doc \
# Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/bastidest/icingaweb2-module-director/archive/${GITREF_DIRECTOR}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
# Icingaweb2 Graphite
    && mkdir -p /usr/local/share/icingaweb2/modules/graphite \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/${GITREF_MODGRAPHITE}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite -f - icingaweb2-module-graphite-${GITREF_MODGRAPHITE}/ \
# Icingaweb2 AWS
    && mkdir -p /usr/local/share/icingaweb2/modules/aws \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/${GITREF_MODAWS}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws -f - icingaweb2-module-aws-${GITREF_MODAWS}/ \
    && wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/2.8.30/aws.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
    && rm aws.zip \
    && true

ADD content/ /
ADD content-full/ /

# Final fixes
RUN true \
    && chmod -R +x /usr/local/etc/icinga2/scripts\
    && mv /usr/local/etc/icinga2/ /usr/local/etc/icinga2.dist \
    && mkdir -p /usr/local/etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && chmod +x /usr/lib/nagios/plugins/check_linux_memory\
    && rm -rf \
        /var/lib/mysql/* \
    && chmod u+s,g+s \
        /bin/ping \
        /bin/ping6 \
        /usr/lib/nagios/plugins/check_icmp 

EXPOSE 80 443 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
