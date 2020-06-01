# environment_platform

## Core

The following instruction must be followed to setup the backend in your local machine

### Requirments

- Ballerina 1.2
- Docker

### Build

To build the Core please execute the following command

```
./setup.sh
```

### Configuration file

Please Make a file called `ballerina.conf` in core/resources as given in the `example.conf` and update the values.

### Run the project using docker

All the volumes and internal networking for mongodb container is set using the docker-composer. Please follow the following commands to build the image and run.

##### Build the image

```
docker-compose build
```

##### Run the image

```
docker-compose up
```

##### Terminate the docker container

- First press `ctl+c`.
- Then run `docker-compose down`

#### Develop and run using docker

When you develop a feature and run using containers. You have to build the jar files using `./setup.sh` and then you have to build and up the dokcer composer.

# Run the project using docker

**Important** - Make sure that configuration files are setup for local machine.

To run the project,

- First `cd core`.
- Then run `./scripts/run-local.sh`.
