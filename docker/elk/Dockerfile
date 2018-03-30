FROM sebp/elk:612

COPY pipeline/beats.conf /etc/logstash/conf.d/02-beats-input.conf
COPY pipeline/nginx.conf /etc/logstash/conf.d/11-nginx.conf
COPY pipeline/app.conf /etc/logstash/conf.d/app.conf
COPY logstash/patterns/symfony.conf /opt/logstash/patterns/symfony