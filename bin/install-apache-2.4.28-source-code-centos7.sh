#!/bin/bash 
yum groupinstall " Development Tools"  -y

yum install expat-devel pcre pcre-devel openssl-devel -y

wget https://github.com/apache/httpd/archive/2.4.28.tar.gz -O httpd-2.4.28.tar.gz

wget https://github.com/apache/apr/archive/1.6.2.tar.gz -O apr-1.6.2.tar.gz

wget https://github.com/apache/apr-util/archive/1.6.0.tar.gz -O apr-util-1.6.0.tar.gz

tar -xzf httpd-2.4.28.tar.gz
tar -xzf apr-1.6.2.tar.gz
tar -xzf apr-util-1.6.0.tar.gz

mv apr-1.6.2 httpd-2.4.28/srclib/apr
mv apr-util-1.6.0 httpd-2.4.28/srclib/apr-util

cd httpd-2.4.28

./buildconf

./configure --enable-ssl --enable-so --with-mpm=event --with-included-apr --prefix=/usr/local/httpd

make

make install

echo "export PATH=/usr/local/httpd/bin:$PATH" > /etc/profile.d/httpd.sh

cat << 'EOF' > /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/httpd/bin/apachectl -k start
ExecReload=/usr/local/httpd/bin/apachectl -k graceful
ExecStop=/usr/local/httpd/bin/apachectl -k graceful-stop
PIDFile=/usr/local/httpd/logs/httpd.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable --now httpd 
