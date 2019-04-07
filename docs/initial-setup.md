# Initial Setup

## Install docker and docker-compose

See the [official instructions](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce-1) to install Docker.

Then add yourself to the `docker` group:
`sudo usermod -aG docker $USER`

Make sure it works fine:
`docker run hello-world`

Also install docker-compose (see the [official instructions](https://docs.docker.com/compose/install/#install-compose)).

## Use premade docker-compose

This tutorial will guide you through the process of configuring each of the apps present.

The included docker-compose file is your best option for having a seamless experience with little manual editing of the configuration files.

It is possible to configure this on your own, however the premade version will work the best, especially while following this tutorial.

1. First, `git clone https://github.com/sebgl/htpc-download-box` into a directory. This is where you will run the full setup from (note: this isn't the same as your media directory)
2. Go into the `base` directory. This is the default, and suggested configuration to use to start.
3. Rename the `.env.example` file included in your chosen directory to `.env`.
4. Continue this guide, and the docker-compose file snippets you see are already ready for you to use. You'll still need to manually configure your `.env` file and other manual configurations.

## Setup environment variables

For each of these images, there is some unique coniguration that needs to be done. Instead of editing the docker-compose file to hardcode these values in, we'll instead put these values in a .env file. A .env file is a file for storing environment variables that can later be accessed in a general-purpose docker-compose.yml file, like the example one in this repository.

Here is an example of what your `.env` file should look like, use values that fit for your own setup.

```bash
# Your timezone, https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TZ=America/New_York
# UNIX PUID and PGID, find with: id $USER
PUID=1000
PGID=1000
# The directory where data and configuration will be stored.
ROOT=/media/my_user/storage/homemedia
```

Things to notice:

- TZ is based on your [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
- The PUID and PGID are your user's ids. Find them with `id $USER`.
- This file should be in the same directory as your `docker-compose.yml` file so the values can be read in.
