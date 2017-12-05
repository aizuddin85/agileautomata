dir = $(shell pwd)
automataproddir = /opt/automata

prod:
	cp -rvf config/automataprod.conf /etc/automata.conf
	if test ! -d ${automataproddir}; then mkdir ${automataproddir}; fi
	if test ! -d ${automataproddir}/var; then mkdir ${automataproddir}/var; fi
	cp -rvf lib ${automataproddir}
	cp -rvf bin ${automataproddir}
	cp -rvf config/script.yml ${automataproddir}
	cp -rvf tooling ${automataproddir}

