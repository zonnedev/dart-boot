#!/bin/bash
mkdir -p certs && cd certs
openssl req -x509 -newkey rsa:4096 -keyout ca-key.pem -out ca.pem -days 365 -nodes -subj "/CN=Boot CA"
openssl req -newkey rsa:4096 -keyout server-key.pem -out server-csr.pem -nodes -subj "/CN=localhost"
openssl x509 -req -in server-csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server.pem -days 365
openssl req -newkey rsa:4096 -keyout device-key.pem -out device-csr.pem -nodes -subj "/CN=charger-001"
openssl x509 -req -in device-csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out device.pem -days 365
rm -f *.csr.pem *.srl
echo "✓ Certificates generated in certs/"
