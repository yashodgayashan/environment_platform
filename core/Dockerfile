FROM ballerina/ballerina:1.2.3

WORKDIR /env_platform

COPY ./target/bin .
COPY ./resources/. ./resources
EXPOSE 9090

CMD ["ballerina", "run", "env_platform.jar","--b7a.config.file=resources/ballerina.conf"]
