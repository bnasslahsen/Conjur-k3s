#!/bin/bash

# GENERATE: Basic Script to generate a SSL certificate CSR request for Conjur Leader (Master) Server

# Global Variables
serverType="leader"
country="US"
state="MA"
city="Boston"
organization="ACME"
commonName="conjur-cluster.acme.corp"

# Generate SSL Key
openssl genrsa -out conjur-$serverType.key 2048

# Generate SSL CSR Request
openssl req -new -sha256 -key conjur-$serverType.key -subj "/C=$country/ST=$state/L=$city/O=$organization/CN=$commonName" -reqexts SAN$serverType -config conjur-openssl.cnf -out conjur-$serverType.csr

# View SSL CSR Request Output
cat conjur-$serverType.csr
