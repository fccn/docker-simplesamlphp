#----------------------------------------------------
# Docker Image for SimpleSAMLPHP based on PHP_FPM
#----------------------------------------------------
FROM php:7-fpm-alpine as base
LABEL maintainer="Paulo Costa <paulo.costa@fccn.pt>"

#---- Read build args
ARG SAML_ROOT=/var/simplesaml
ARG SAML_OPTS=/opt/simplesaml

ENV TZ=Europe/Lisbon

#add testing and community repositories
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
  && echo '@community http://nl.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
  && echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
  && apk update && apk upgrade --no-cache --available && apk add --upgrade apk-tools@edge \
#------ set timezone
  ; apk --no-cache add ca-certificates && update-ca-certificates \
  ; apk add --update tzdata && cp /usr/share/zoneinfo/Europe/Lisbon /etc/localtime \
#--- additional packages
  ; apk add --no-cache --update git zip \
  ; rm -rf /var/cache/apk/* \
#---- add application user and group
  ; addgroup -g 1000 application && adduser -u 1000 -G application -D application

#-install composer and simplesamlphp
WORKDIR /tmp
RUN curl --silent --show-error https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
#--- install simplesamlphp
  && curl -L -o simplesamlphp.tar.gz https://simplesamlphp.org/download?latest \
  && tar -xf simplesamlphp.tar.gz -C /tmp \
  && mv simplesamlphp-* ${SAML_ROOT} \
#---- add custom module
  && curl -L -o advancedauthfilters.tar.gz https://github.com/fccn/simplesaml-mod-advancedauthfilters/archive/1.0.0.tar.gz \
  && tar -xzf advancedauthfilters.tar.gz && mv simplesaml-mod-advancedauthfilters-1.0.0 ${SAML_ROOT}/modules/advancedauthfilters \
#---  change ownership of SAML folders
  ; chown -R application:application ${SAML_ROOT} \
  ; mkdir -p ${SAML_OPTS} && chown -R application:application ${SAML_OPTS}

  # replace custom module operation with this in future...
  # composer config fccn.advauthfilters vcs <https repo url>
  # composer require fccn/simplesamlphp-module-advancedauthfilters

USER application

WORKDIR ${SAML_ROOT}

#--- activate most used modules and change ownership of SAML folders
RUN touch ${SAML_ROOT}/modules/metarefresh/enable \
	&& touch ${SAML_ROOT}/modules/cron/enable \
	&& touch ${SAML_ROOT}/modules/exampleauth/enable \
  && touch ${SAML_ROOT}/modules/advancedauthfilters/enable \
  && cp ${SAML_ROOT}/modules/cron/config-templates/*.php ${SAML_ROOT}/config/ \
	&& cp ${SAML_ROOT}/modules/metarefresh/config-templates/*.php ${SAML_ROOT}/config/ \
#---- run update (fix for php 7.3 - removing php-cs-fixer)
  ; composer remove --dev friendsofphp/php-cs-fixer \
  ; composer update --no-dev \
#--- place saml configurations on opts folder
  ; mkdir -p ${SAML_ROOT}/cert && mkdir -p ${SAML_ROOT}/config \
  && mkdir -p ${SAML_ROOT}/metadata && mkdir -p ${SAML_ROOT}/log \
  ; mv ${SAML_ROOT}/cert ${SAML_OPTS}/cert && ln -s ${SAML_OPTS}/cert ${SAML_ROOT}/cert \
  ; mv ${SAML_ROOT}/config ${SAML_OPTS}/config && ln -s ${SAML_OPTS}/config ${SAML_ROOT}/config \
  ; mv ${SAML_ROOT}/metadata ${SAML_OPTS}/metadata && ln -s ${SAML_OPTS}/metadata ${SAML_ROOT}/metadata \
  ; mv ${SAML_ROOT}/log ${SAML_OPTS}/log && ln -s ${SAML_OPTS}/log ${SAML_ROOT}/log

USER root

FROM php:7-fpm-alpine as simplesamlphp
LABEL maintainer="Paulo Costa <paulo.costa@fccn.pt>"

#---- Read build args
ARG SAML_ROOT=/var/simplesaml
ARG SAML_OPTS=/opt/simplesaml

COPY --from=base ${SAML_ROOT} ${SAML_ROOT}
COPY --from=base ${SAML_OPTS} ${SAML_OPTS}

ENV TZ=Europe/Lisbon

#update packages and set timezone
RUN apk update && apk upgrade --no-cache --available \
#------ set timezone
  ; apk --no-cache add ca-certificates && update-ca-certificates \
  ; apk add --update tzdata && cp /usr/share/zoneinfo/Europe/Lisbon /etc/localtime \
#--- additional packages
  ; apk add --no-cache --update git zip \
  ; rm -rf /var/cache/apk/* \
#---- add application user and group
  ; addgroup -g 1000 application && adduser -u 1000 -G application -D application \
#---- change ownership of SAML metadata and log folders
  ; chown -R application:application ${SAML_ROOT}/metadata \
  ; chown -R application:application ${SAML_ROOT}/log \
  ; chown -R application:application ${SAML_OPTS}/metadata \
  ; chown -R application:application ${SAML_OPTS}/log \
#---- display version info
  ; echo "Using: "; echo $(php -v);  echo "Simplesaml version: " \
  ; cat ${SAML_ROOT}/composer.json | grep version | head -1 | awk -F: '{ print $2 }' |  sed 's/[",]//g'

WORKDIR $SAML_ROOT

USER application
