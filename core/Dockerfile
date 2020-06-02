FROM ballerina/ballerina:1.2.3

WORKDIR /env_platform

COPY ./scripts .
COPY ./target/bin ./target
COPY ./resources/. ./resources
EXPOSE 9090 9080

CMD ["./run-docker.sh"]
