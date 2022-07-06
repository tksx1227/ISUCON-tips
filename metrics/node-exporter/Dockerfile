FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    iputils-ping \
    net-tools \
    stress

WORKDIR /opt

ARG node_exporter="node_exporter-1.3.1.linux-amd64"
ARG node_exporter_path="https://github.com/prometheus/node_exporter/releases/download/v1.3.1/${node_exporter}.tar.gz"
RUN wget ${node_exporter_path} && \
    tar xvfz "${node_exporter}.tar.gz" && \
    rm "${node_exporter}.tar.gz"

ENTRYPOINT [ "/opt/node_exporter-1.3.1.linux-amd64/node_exporter" ]
