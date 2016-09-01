FROM eu.gcr.io/peopledata-product-team/td.base:latest 

MAINTAINER peopledata-product-team@thoughtworks.com

RUN groupadd nginx && \
    useradd -g nginx nginx

# Download the latest source and build it
RUN dnf -y -q install gcc gcc-c++ make zlib-devel pcre-devel openssl-devel tar && \
    nginxVersion="1.11.2" && \
    cd /usr/local/src && \
    wget --quiet http://nginx.org/download/nginx-$nginxVersion.tar.gz && \
    tar -xzf nginx-$nginxVersion.tar.gz && \
    ln -sf nginx-$nginxVersion nginx && \
    cd nginx && \
    ./configure \
      --user=nginx                          \
      --group=nginx                         \
      --prefix=/usr/share/nginx                   \
      --sbin-path=/usr/sbin/nginx           \
      --conf-path=/etc/nginx/nginx.conf     \
      --pid-path=/var/run/nginx/nginx.pid         \
      --lock-path=/var/run/nginx/nginx.lock       \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --with-http_gzip_static_module        \
      --with-http_stub_status_module        \
      --with-http_ssl_module                \
      --with-pcre                           \
      --with-file-aio                       \
      --with-http_realip_module             \
      --without-http_scgi_module            \
      --without-http_uwsgi_module           \
      --without-http_fastcgi_module      && \
    make && \
    make install && \
    rm -rf /usr/local/src/nginx* && \
    dnf -y -q autoremove gcc gcc-c++ make zlib-devel pcre-devel openssl-devel && \
    dnf -y -q clean all

# Setup directories and ownership, as well as allowing nginx to bind to low ports
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/run/nginx && \
    mkdir -p /usr/share/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /var/run/nginx && \
    chown -R nginx:nginx /etc/nginx && \
    chown -R nginx:nginx /usr/share/nginx

# Temporarily removed this, see https://github.com/docker/docker/issues/20658
# RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

# Add latest pip
RUN wget --quiet https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py

# Download and setup lets encrypt
RUN dnf -y -q install ca-certificates libffi-devel openssl-devel python-devel redhat-rpm-config git make gcc gcc-c++ && \
    mkdir -p /tmp/src && \
    git clone https://github.com/kuba/simp_le.git /tmp/src/simp_le && \
    cd /tmp/src/simp_le && \
    python ./setup.py install && \
    dnf -y -q autoremove gcc gcc-c++ make git redhat-rpm-config && \
    dnf -y -q clean all

# Generate a temporary self signed certificate until letsencrypt works
RUN dnf -y -q install openssl && \
    dnf -y -q clean all

# Setup NGINX configuration
RUN mkdir -p /etc/nginx/conf.d
COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /usr/local/etc/nginx
COPY ssl.default.conf /usr/local/etc/nginx
COPY start.sh /usr/local/bin/

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/bin/start.sh"]
