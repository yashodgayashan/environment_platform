#!/bin/bash

ballerina run ./target/env_platform.jar --b7a.config.file=./resources/ballerina.conf &
ballerina run ./target/auth_service.jar --b7a.config.file=./resources/ballerina.conf 
