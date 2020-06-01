# environment_platform

## Module Core(contains the back-end functionalities).

The following instructions below will guide you through the process of setting up the back-end server in your local machine.

### Prerequisites

- Ballerina 1.2.x
- Docker

### How to Build?

To build the module execute the command:

```
./setup.sh
```

### Create a configuration file

Make a file named `ballerina.conf` in `core/resources`. You can refer the file `example.conf` located at `core/resources/` for more details. Then, update the created file with your preference of values.

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

When you develop a feature and run using containers. You have to build the jar files using `./setup.sh` and then you have to build and up the docker composer.

# Run the project using docker

**Important** - Make sure that configuration files are setup for local machine.

To run the project,

- First `cd core`.
- Then run `./scripts/run-local.sh`.
