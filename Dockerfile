FROM ubuntu:20.04
#********************************************************************

ENV OLS_VERSION                                     1.7.14
ENV PHP_VERSION                                     lsphp80
# configuracion del nombre del virtualhost

ENV JIMENOZKI_DOMAIN                                misitio.tld
# Configuracion de directorios personalizados

ENV JIMENOZKI                                       /jimenozki
ENV JIMENOZKI_CONFIG                                /etc/jimenozki
ENV JIMENOZKI_LOG                                   /var/log/jimenozki
ENV JIMENOZKI_ADMIN                                 /jimenozki/ols
# Configuracion de Usuarios y Contrasenas Administrador OLS

ENV JIMENOZKI_ADMIN_USERNAME                        jimenozki
ENV JIMENOZKI_ADMIN_PASSWORD                        jimenozki
ENV JIMENOZKI_ADMIN_PREFIX                          true

# Configuracion de Base de Datos jimenozki-install
ENV JIMENOZKI_DB_HOST                               jimenozki
ENV JIMENOZKI_DB_NAME                               jimenozki
ENV JIMENOZKI_DB_PASSWORD                           jimenozki
ENV JIMENOZKI_DB_USER                               jimenozki
ENV JIMENOZKI_DB_PREFIX                             _Jmnzk
ENV JIMENOZKI_DB_LOCALE                             es_ES
ENV JIMENOZKI_DB_CHARSET                            utf8

# Configuracion de htpasswd
ENV JIMENOZKI_BASIC_AUTH_PASSWORD                   jimenozki
ENV JIMENOZKI_BASIC_AUTH_USERNAME                   jimenozki

# Enable basic auth for wp-login.php
ENV JIMENOZKI_BASIC_AUTH_WP                         false
#INVESTIGAR NOO APARECE EN OTRO LADO
#ENV DEMYX_WP_CONFIG                             "${DEMYXjimenozki}/wp-config.php"

#### httpd_config
# Configuracion  Acceso a Admin OLS http_config
ENV JIMENOZKI_ADMIN_IP                              ALL

#habilitar o deshabilitar XMLRPC
ENV JIMENOZKI_XMLRPC                                false
ENV JIMENOZKI_CLIENT_THROTTLE_BANDWIDTH_IN          0
ENV JIMENOZKI_CLIENT_THROTTLE_BANDWIDTH_OUT         0
ENV JIMENOZKI_CLIENT_THROTTLE_BAN_PERIOD            60
ENV JIMENOZKI_CLIENT_THROTTLE_BLOCK_BAD_REQUEST     1
ENV JIMENOZKI_CLIENT_THROTTLE_DYNAMIC               1000
ENV JIMENOZKI_CLIENT_THROTTLE_GRACE_PERIOD          30
ENV JIMENOZKI_CLIENT_THROTTLE_HARD_LIMIT            2000
ENV JIMENOZKI_CLIENT_THROTTLE_SOFT_LIMIT            1500
ENV JIMENOZKI_CLIENT_THROTTLE_STATIC                1000
ENV JIMENOZKI_RECAPTCHA_CONNECTION_LIMIT            500
ENV JIMENOZKI_RECAPTCHA_ENABLE                      1
ENV JIMENOZKI_RECAPTCHA_TYPE                        2
ENV JIMENOZKI_CRAWLER_LOAD_LIMIT                    5.2
ENV JIMENOZKI_CRAWLER_USLEEP                        1000

# Configuracion PHP
ENV JIMENOZKI_PHP_LSAPI_CHILDREN                    2000
ENV JIMENOZKI_PHP_MAX_EXECUTION_TIME                300
ENV JIMENOZKI_PHP_MEMORY                            256M
ENV JIMENOZKI_PHP_OPCACHE                           true

# Maxima tamano de archivo de carga
ENV JIMENOZKI_PHP_UPLOAD_LIMIT                      128M
ENV JIMENOZKI_TUNING_CONNECTION_TIMEOUT             300
ENV JIMENOZKI_TUNING_KEEP_ALIVE_TIMEOUT             300
ENV JIMENOZKI_TUNING_MAX_CONNECTIONS                20000
ENV JIMENOZKI_TUNING_MAX_KEEP_ALIVE                 1000
ENV JIMENOZKI_TUNING_SMART_KEEP_ALIVE               1000
ENV JIMENOZKI_CACHE                                 false
ENV TZ                                              America/Panama
#ENV PATH                                        "${PATH}:/usr/local/lsws/${jimenozki_LSPHP_VERSION}/bin"
#***********************************************************************
# Actualizar sistema
RUN set -ex; \
        apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        cron \
         curl \
        ed \
        jq \
        procps \
        ruby \
        sudo \
        tzdata \
        wget
# Instalar openlitespeed
RUN wget https://openlitespeed.org/preuse/openlitespeed-$OLS_VERSION.tgz && \
    tar xzf openlitespeed-$OLS_VERSION.tgz && cd openlitespeed && ./install.sh && \
    echo 'cloud-docker' > /usr/local/lsws/PLAT && rm -rf /openlitespeed && rm /openlitespeed-$OLS_VERSION.tgz
# Instala lsphp y los paquetes necesarios php
RUN apt-get install mysql-client $PHP_VERSION $PHP_VERSION-common $PHP_VERSION-mysql $PHP_VERSION-opcache \
    $PHP_VERSION-curl $PHP_VERSION-imagick $PHP_VERSION-redis $PHP_VERSION-memcached $PHP_VERSION-intl -y
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then apt-get install $PHP_VERSION-json -y; fi"]
# Instala utilizadad de actualizacion de ols por linea e comando
RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh
# Instala Wordpress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
        chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp && \
        ln -s /usr/local/lsws/$PHP_VERSION/bin/php /usr/bin/php
# Configurar usuario non root del sistema
 # Crea el usuario sin privilegios del sistena
RUN adduser --gecos '' --disabled-password jimenozki; \
    # Create directorios para jimenozki
    install -d -m 0755 -o jimenozki -g jimenozki "$JIMENOZKI"; \
    install -d -m 0755 -o jimenozki -g jimenozki "$JIMENOZKI_CONFIG"; \
    install -d -m 0755 -o jimenozki -g jimenozki "$JIMENOZKI_LOG"; \
    # Actualiza .bashrc
    echo 'PS1="$(whoami)@\h:\w \$ "' > /home/jimenozki/.bashrc; \
    echo 'PS1="$(whoami)@\h:\w \$ "' > /root/.bashrc
#RUN wget -O -  https://get.acme.sh | sh
#EXPOSE 7080
# Configuracion del lsphp por defecto
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi"]
# Crear directorio para lsadm user
RUN install -d -m 0755 -o lsadm -g lsadm "$JIMENOZKI_CONFIG"/ols; \
    # configurar enlases simbolicos para lsws
    ln -sf "$JIMENOZKI_CONFIG"/ols/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf; \
    #ln -sf "$JIMENOZKI_CONFIG"/ols/admin_config.conf /usr/local/lsws/admin/conf/admin_config.conf; \
    ln -s "$JIMENOZKI_CONFIG"/ols /usr/local/lsws/conf/vhosts
RUN su -c "cd /jimenozki; \
        wp core download --locale=es_ES --force;" -s /bin/sh jimenozki
# Copiar archivos necesarios de configuracion
COPY --chown=root:root bin /usr/local/bin
# Configuracion de sudo sudoers
RUN echo "jimenozki ALL=(ALL) NOPASSWD:SETENV: /usr/local/lsws/bin/lswsctrl, /usr/local/bin/jimenozki-admin, /usr/local/bin/jimenozki-config, /usr/local/bin/jimenozki-htpasswd, /usr/local/bin/jimenozki-lsws" > /etc/sudoers.d/jimenozki; \
# Finalize Configurar permisos
    chown -R root:root /usr/local/bin
EXPOSE 80

WORKDIR "$JIMENOZKI"

USER jimenozki

ENTRYPOINT ["jimenozki-entrypoint"]