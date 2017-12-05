#!/bin/sh

if [ $# -lt 1 ]; then
   echo "Usage: $0 <dev|prod>"
   exit 1
fi

if [ "$1" = "dev" ]; then
   DBNAME=automatadev
else
   DBNAME=automata
fi

SQLOUT=qsql.tmp
mysql -u root -pShell123 -e "select * from $DBNAME.queue;" > qsql.tmp

RX1="The message flow is broken"
RX2="CPU"
RX3="Disk space"
RX4="Not updating hosts file because of DNS errors"
RX5="RGS port check failed"

echo -e "Database =" $DBNAME
echo -e "Total\t OK\tFAIL\tRegex"
echo -e "-----\t----\t----\t-----"
for i in "$RX1" "$RX2" "$RX3" "$RX4" "$RX5"
do 
  #echo -e `egrep "$i" $SQLOUT | wc -l` "\t:" "$i" ;
  IREGEX=$i
  ITOTAL=$(egrep "$i" $SQLOUT | wc -l)
  IOK=$(egrep "$i" $SQLOUT | grep -v READY | awk '{print $(NF-8)}' | grep 2 | wc -l)
  IFAIL=$(egrep "$i" $SQLOUT | grep -v READY | awk '{print $(NF-8)}' | grep 3 | wc -l)

  echo -e $ITOTAL "\t" $IOK "\t" $IFAIL "\t" $IREGEX
done

echo -e "=====\n"`egrep 'LUX|WIN' $SQLOUT | wc -l` "\n"; 

echo "---------------------------------------------"
echo -e "Date\t\tTotal\t OK\tFAIL\tOther"
echo -e "----\t\t-----\t----\t----\t-----"
for i in $(cat $SQLOUT | awk '{print $(NF-5)}' | grep -v time | sort -u)
do
  IDATE=$i
  ITOTAL=$(grep $i $SQLOUT | wc -l )
  IOK=$(grep $i $SQLOUT | grep -v READY | awk '{print $(NF-8)}' | grep 2 | wc -l )
  IFAIL=$(grep $i $SQLOUT | grep -v READY | awk '{print $(NF-8)}' | grep 3 | wc -l )
  IOTHER=$(grep $i $SQLOUT | grep -v READY | awk '{print $(NF-8)}' | egrep -v '2|3' | wc -l )
  
  echo -e $IDATE "\t" $ITOTAL "\t" $IOK "\t" $IFAIL "\t" $IOTHER
done
echo "----------------------------------------------"

rm $SQLOUT
