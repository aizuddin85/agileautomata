dir = $(shell pwd)
httpdir = /etc/httpd/conf.d
tlscertdir = /etc/pki/tls/certs
tlskeydir = /etc/pki/tls/private/

all:
	ln -s /var/www/html/automata automata-web
	cp -rvf conf/automata.conf $(httpdir)
	cp -rvf certs/automata.key $(tlskeydir)
	cp -rvf certs/automata.crt $(tlscertdir)
	systemctl reload httpd

