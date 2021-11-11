#!/bin/bash
if [ -z "$1" ]
  then
    echo "No server ip supplied"
    exit
fi
if [ -z "$2" ]
  then
    echo "No server name supplied"
    exit
fi

CFG_PATH=$(dirname "$0")

mkdir tmp

IP="$1"
NAME="server"
DNS="$2"
cat "$CFG_PATH/server.cnf" > "./tmp/$NAME.cnf"
echo "DNS.2 = $DNS">>"./tmp/$NAME.cnf"
echo "IP.1 = 127.0.0.1" >> "./tmp/$NAME.cnf" 
echo "IP.2 = $IP" >> "./tmp/$NAME.cnf" 

echo "** Setup certificates for server $NAME**"
echo ""

echo "Create server key pair & certificate request:"
openssl req -nodes -new -keyout $NAME.key -out ./tmp/$NAME.csr -config ./tmp/$NAME.cnf
echo ""
echo "Generate server certificate"
openssl x509 -days 3650 -req -in ./tmp/$NAME.csr -CA "$CFG_PATH/cert/root.cer" -CAkey "$CFG_PATH/cert/root.key" -CAcreateserial -out $NAME.cer -extfile ./tmp/$NAME.cnf -extensions x509_ext
echo ""

rm -r tmp