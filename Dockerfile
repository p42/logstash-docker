#Install and configure [] 

FROM docker.elastic.co/logstash/logstash:5.6.3
MAINTAINER Brandon Cone - bcone@esu10.org

COPY container_files /

# I'm not certain we actually need to run anything since we're extending the existing logstash image...Pending test.
# RUN logstash-plugin install logstash-output-mqtt