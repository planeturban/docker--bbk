FROM ubuntu

RUN mkdir -p /app/
RUN apt-get update && apt-get install -y curl
RUN curl https://frontend.bredbandskollen.se/download/bbk_cli_linux_amd64-1.0 --output /app/bbk
RUN chmod +x /app/bbk

RUN apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

ADD scripts/ /app/

CMD bash -c /app/init_test_connection.sh
