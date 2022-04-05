FROM cmssw/exporters:latest as exporters
FROM cmssw/filebeat:latest as filebeat
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

FROM alpine:3.15
RUN mkdir -p /data
COPY --from=exporters /data/process_exporter /data
COPY --from=exporters /data/process_monitor.sh /data
COPY --from=filebeat /usr/share/filebeat /usr/share/filebeat
COPY --from=filebeat /usr/bin/filebeat /usr/bin/filebeat

# run the service
ENV PATH="/data/gopath/bin:/data:${PATH}"
ADD monitor.sh /data/monitor.sh
RUN chmod +x /data/*.sh
WORKDIR /data
CMD ["tail", "-f", "monitor.sh"]
