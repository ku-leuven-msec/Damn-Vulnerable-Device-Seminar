#!/bin/bash
mkdir cert
mkdir tmp

echo "Create selfisgned CA Certificate"
openssl req -x509 -new -keyout ./cert/root.key -out ./cert/root.cer -config root.cnf

#echo "Create server key pair & certificate request:"
#openssl req -nodes -new -keyout ./cert/server.key -out ./tmp/server.csr -config server.cnf

#echo "Generate server certificate"
#openssl x509 -days 3650 -req -in server.csr -CA ./cert/root.cer -CAkey ./cert/root.key -CAcreateserial -out ./cert/server.cer -extfile server.cnf -extensions x509_ext

echo "Create client key pair & certificate request:"
openssl req -nodes -new -keyout ./cert/client.key -out ./tmp/client.csr -config client.cnf

echo "Generate client certificate"
openssl x509 -req -in ./tmp/client.csr -CA ./cert/root.cer -CAkey ./cert/root.key -out ./cert/client.cer -CAcreateserial -days 365 -extfile client.cnf -extensions x509_ext

echo "Create pkcs12 keystore for Android:"
openssl pkcs12 -export -inkey ./cert/client.key  -in ./cert/client.cer -certfile ./cert/root.cer -out ./cert/client.pfx

echo "extract public key from client certificate"
openssl x509 -pubkey -noout -in ./cert/client.cer > ./cert/client.pub

echo "convert public key to RSA key"
ssh-keygen -f ./cert/client.pub -i -mPKCS8 > ./cert/mobile.rsa

cat ./cert/root.cer > ./cert/clients.pem
cat ./cert/client.cer >> ./cert/clients.pem

cp ./cert/clients.pem ../credentials/
cp ./cert/root.cer ../credentials/
cp ./cert/mobile.rsa ../credentials/

rm -r tmp