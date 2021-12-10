FROM daocloud.io/library/php:5.6.25-fpm

MAINTAINER Minho <longfei6671@163.com>

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak \
	&& echo " " > /etc/apt/sources.list \
	&& echo "deb http://mirrors.aliyun.com/debian jessie main" >> /etc/apt/sources.list \
	&& echo "deb http://mirrors.aliyun.com/debian jessie-updates main" >> /etc/apt/sources.list 

RUN apt-get clean && apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
		libpcre3-dev \
		gcc \
		make \
        bzip2 \
	libbz2-dev \
	libmemcached-dev \
        libyaml-dev \
        libssl-dev \
	git \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
	&& docker-php-ext-install mcrypt\
    && docker-php-ext-install mysqli \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install zip \
	&& docker-php-ext-install pdo_mysql \
	&& apt-get -y autoremove \ 
	&& apt-get -y autoclean 
	
WORKDIR /usr/src/php/ext/
RUN mkdir redis && curl -L http://pecl.php.net/get/redis-3.1.6.tgz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

# install mongo
RUN  pecl install mongo \
  && docker-php-ext-enable mongo

WORKDIR /usr/src/php/ext/
RUN mkdir yaml && curl -L http://pecl.php.net/get/yaml-1.2.0.tgz | tar xvz -C /usr/src/php/ext/yaml --strip 1 \
    && echo 'yaml' >> /usr/src/php-available-exts \
    && docker-php-ext-install yaml

ENV PHALCON_VERSION=3.2.0

# Compile Phalcon
RUN set -xe && \
        curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
        tar xzvf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && ./install && \
        echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini && \
        cd ../.. && rm -rf v${PHALCON_VERSION}.tar.gz cphalcon-${PHALCON_VERSION} 
        # Insall Phalcon Devtools, see https://github.com/phalcon/phalcon-devtools/
        #curl -LO https://github.com/phalcon/phalcon-devtools/archive/v${PHALCON_VERSION}.tar.gz && \
        #tar xzf v${PHALCON_VERSION}.tar.gz && \
        #mv phalcon-devtools-${PHALCON_VERSION} /usr/local/phalcon-devtools && \
        #ln -s /usr/local/phalcon-devtools/phalcon.php /usr/local/bin/phalcon

#Composer
RUN curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x /usr/bin/composer
ENV COMPOSER_HOME=/tmp/composer



#igbinary
RUN set -xe && \
        curl -LO https://github.com/igbinary/igbinary/archive/1.2.1.tar.gz && \
		tar xzf 1.2.1.tar.gz && cd igbinary-1.2.1 && \
		phpize && ./configure CFLAGS="-O2 -g" --enable-igbinary && make && make install && \
		cd ../ && rm -rf igbinary-1.2.1
	
	
RUN docker-php-source extract \
	&& cd /usr/src/php/ext/bcmath \
	&& phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install \
	&& make clean \
	&& docker-php-source delete
	
# PHP config
ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf
#
# RUN set -xe && \
#	curl -LO https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_1.tar.gz && \
#	tar xzf XDEBUG_2_4_1.tar.gz && cd xdebug-XDEBUG_2_4_1 && \
#	phpize && ./configure --enable-xdebug && make && make install && \
#	cd ../ && rm -rf xdebug-XDEBUG_2_4_1
	
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm"]
