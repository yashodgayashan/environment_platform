#!/bin/bash

ballerina run target/bin/env_platform.jar --b7a.config.file=resources/ballerina.conf &
ballerina run target/bin/auth_service.jar --b7a.config.file=resources/ballerina.conf 