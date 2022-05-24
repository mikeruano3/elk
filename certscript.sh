#!/bin/bash

sudo su
location="/home/elkadmin/tmp/cert_blog_1"
certslocation="${location}/certs"
echo "Certs location ---> ${certslocation}"

rm -rf ${location}
mkdir -p ${certslocation}
cd ${location}

echo "instances:
  - name: 'node1'
    dns: [ 'node1.elastic.test.com', '52.173.64.187' ]
  - name: 'my-kibana'
    dns: [ 'kibana.local', '52.173.64.187' ]
  - name: 'logstash'
    dns: [ 'logstash.local', '52.173.64.187' ]
" >> instance.yml


echo "--- Generating certificates ---"
cd /usr/share/elasticsearch
bin/elasticsearch-certutil cert --keep-ca-key --pem --in ${location}/instance.yml --out ${location}/certs.zip
unzip $location/certs.zip -d $certslocation

echo "--- Copying elasticsearch certs ---"
mkdir -p /etc/elasticsearch/certs/
rm /etc/elasticsearch/certs/*
cp ${certslocation}/ca/ca* -d /etc/elasticsearch/certs/
cp ${certslocation}/node1/node1* -d /etc/elasticsearch/certs/

echo "--- Copying kibana certs ---"
mkdir -p /etc/kibana/config/certs/
rm /etc/kibana/config/certs/*
cp ${certslocation}/ca/ca.crt -d /etc/kibana/config/certs/
cp ${certslocation}/my-kibana/my-kibana* -d /etc/kibana/config/certs/

echo "--- Copying logstash certs ---"
mkdir -p /etc/logstash/config/certs/
rm /etc/logstash/config/certs/*
cp ${certslocation}/ca/ca.crt -d /etc/logstash/config/certs/
cp ${certslocation}/logstash/logstash* -d /etc/logstash/config/certs/
openssl pkcs8 -in  /etc/logstash/config/certs/logstash.key -topk8 -nocrypt -out /etc/logstash/config/certs/logstash.pkcs8.key
chmod --reference=/etc/logstash/config/certs/logstash.key /etc/logstash/config/certs/logstash.pkcs8.key

echo "--- Stoping elasticsearch ---"
service elasticsearch stop
echo "--- Starting elasticsearch ---"
service elasticsearch start

echo "--- Stoping kibana ---"
service kibana stop
echo "--- Starting kibana ---"
service kibana start

echo "--- Starting logstash ---"
service logstash start

echo "-- Testing elastic --"
cd /usr/share/elasticsearch && curl -X GET "https://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=50s&pretty" --key certificates/elasticsearch-ca.pem -k -u elastic
cd ~
