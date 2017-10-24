#Install and configure [] 

FROM centos
MAINTAINER Brandon Cone - bcone@esu10.org

COPY container_files /

# I'm not certain we actually need to run anything since we're extending the existing logstash image...Pending test.
# RUN logstash-plugin install logstash-output-mqtt
RUN yum install -y git
WORKDIR /usr/share
ENTRYPOINT ["/bin/bash"]
CMD ["/scripts/run.sh", "/var", "logstash-config", "git@git.ops.esu10.org:Operations/logstash-config.git"]