# Pi HTPC Download Box

Sonarr / Radarr / Bazarr / Jackett / NZBGet / Transmission / Deluge / NordVPN / Plex

TV shows and movies download, sort, with the desired quality and subtitles, behind a VPN (optional), ready to watch, in a beautiful media player.
All automated.

## Table of Contents

- [Pi HTPC Download Box](#htpc-download-box)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Monitor TV shows/movies with Sonarr and Radarr](#overview)
    - [Organize libraries and play videos with Plex](#overview)
  - [Hardware configuration](#overview)
  - [Software stack](#overview)
  - [Installation guide](#installation-guide)
    - [Introduction](#introduction)
    - [Hypriot OS](#hypriot-oS)
    - [Setup NTFS folder](#setup-ntfs-folder)
      - [Create NTFS folder on NAS](create-ntfs-folder-on-NAS)
      - [Mount NTFS folder on Pi](mount-ntfs-folder-on-Pi)
    - [Setup Transmission](#overview)
    - [Setup Deluge](#overview)
    - [Setup a VPN Container](#overview)
    - [Setup Jackett](#overview)
    - [Setup Plex](#overview)
    - [Media Server Docker Container](#overview)
    - [Configuration](#overview)
    - [Setup Plex clients](#overview)
    - [Setup Sonarr](#overview)
    - [Setup Radarr](#overview)
    - [Setup Bazarr](#overview)
      - [Remotly Add Movies Using trakt.tv And List](#remotly-add-movies-using-trakttv-and-list)
    - [Reduce Pi Power Consumption](#reduce-pi-power-consumption)
      - [Disable HDMI](#disable-hdmi)
      - [Turn Off LEDs](#turn-off-leds)
      - [Disable Wifi](#disable-wifi)
      - [Disable Bluetooth](#disable-bluetooth)
      - [Docker container](#docker-container)
      - [Configuration](#configuration)
      - [Give it a try](#give-it-a-try)
      - [Movie discovering](#movie-discovering)
  - [Usefull Commands](#usefull-commands)
  - [TODO](#todo)

## Overview
[See original instructions](https://github.com/sebgl/htpc-download-box#overview)


## Hardware configuration

I have a Synology DS2013j but it's too old to run sonarr/jackett/radarr/plex properly. The movies and tvshows will be stored in a NTFS folder on my nas, the softwares configurations will be stored in the PI. SQLlite doesn't like to be in a network folder, give a lot of `database locked` errors.

I use a Pi 3B but I have added the instructions for older Pi like the 1B and tested it but wasn't able to make it work.

![Error](img/raspberry_pi_1b_failure.png)

## Installation guide

### Introduction

The idea is to set up all these components as Docker containers in a `docker-compose.yml` file.
We'll reuse community-maintained images (special thanks to [linuxserver.io](https://www.linuxserver.io/) for many of them).
I'm assuming you have some basic knowledge of Linux and Docker.
A general-purpose `docker-compose` file is maintained in this repo [here](https://github.com/marchah/pi-htpc-download-box/blob/master/docker-compose.yml).

The stack is not really plug-and-play. You'll see that manual human configuration is required for most of these tools. Configuration is not fully automated (yet?), but is persisted on reboot. Some steps also depend on external accounts that you need to set up yourself (usenet indexers, torrent indexers, vpn server, plex account, etc.). We'll walk through it.

Optional steps described below that you may wish to skip:

- Using a VPN server for Transmission and/or Deluge incoming/outgoing traffic.
- Using newsgroups (Usenet): you can skip NZBGet installation and all related Sonarr/Radarr indexers configuration if you wish to use bittorrent only.

### Hypriot OS

I recently switched to [Hypriot OS](https://blog.hypriot.com/), it come with docker preinstall and support all the Pi versions.

Default ssh username/password is `pirate/hypriot`.

```
sudo apt-get update
sudo apt-get install nfs-common
```

Then add yourself to the `docker` group:
`sudo usermod -aG docker myuser`

Make sure it works fine:
`docker run hello-world`

Also install docker-compose (see the [official instructions](https://docs.docker.com/compose/install/#install-compose)).

### (optional) Use premade docker-compose

This tutorial will guide you along the full process of making your own docker-compose file and configuring every app within it, however, to prevent errors or to reduce your typing, you can also use the general-purpose docker-compose file provided in this repository.

1. First, `git clone https://github.com/sebgl/htpc-download-box` into a directory. This is where you will run the full setup from (note: this isn't the same as your media directory)
2. Rename the `.env.example` file included in the repo to `.env`.
3. Continue this guide, and the docker-compose file snippets you see are already ready for you to use. You'll still need to manually configure your `.env` file and other manual configurations.


### (optional) Use premade Vagrant box

You can also use a premade Vagrant box, that will spin up an Ubuntu virtual machine and bootstrap the environment from the `docker-compose` file described above.

After ensuring Vagrant is installed on your machine:

1. Run `vagrant up` to bootstrap the vagrant box
2. Run `vagrant ssh` to ssh into the box
3. Use the default `192.168.7.7` IP to access the box services from a local machine

### Setup environment variables


Instead of editing the docker-compose file to hardcode these values in, we'll instead put these values in a .env file. A .env file is a file for storing environment variables that can later be accessed in a general-purpose docker-compose.yml file, like the example one in this repository.
For each of these images, there is some unique configuration that needs to be done. Instead of editing the docker-compose file to hardcode these values in, we'll instead put these values in a .env file. A .env file is a file for storing environment variables that can later be accessed in a general-purpose docker-compose.yml file, like the example one in this repository.

Here is an example of what your `.env` file should look like, use values that fit for your own setup.
SQLlite use by sonarr and radarr doesn't like to be on a network folder so I separated the config folders env variable to keep them in the Pi.
Env variables will only be used by Yacht, the rest will be configured directly on Yacht web UI.

https://github.com/bubuntux/nordvpn#local-network-access-to-services-connecting-to-the-internet-through-the-vpn

```sh
# Your timezone, https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TZ=America/Los_Angeles
# UNIX PUID and PGID, find with: id $USER
PUID=1000
PGID=1000
# Local network mask, find with: ip route | awk '!/ (docker0|br-)/ && /src/ {print $1}'
NETWORK=192.168.0.0/24
# The directory where data will be stored.
ROOT=/media
# The directory where configuration will be stored.
CONFIG=/config
#NordVPN informations
VPN_USER=usero@email.com
VPN_PASSWORD=password
VPN_COUNTRY=CA
```

### Setup NAS

#### Create NTFS folder on NAS

This is the instructions for a Synology but should be pretty much the same for any NAS.

[Instructions](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/File_Sharing/How_to_access_files_on_Synology_NAS_within_the_local_network_NFS)

#### Mount NTFS folder on Pi


```
mkdir /home/pirate/Plex
```

Add in `/etc/fstab`

```
<your-nas-ip-address>:/volume1/Plex /home/pirate/Plex nfs rw,hard,intr,rsize=8192,wsize=8192,timeo=14 0 0
```

Re mount

```
sudo mount -a
```

```


#### Remotly Add Movies Using trakt.tv And List

[Instructions](https://www.reddit.com/r/radarr/comments/aixb2i/how_to_setup_trakttv_for_lists/)

### Reduce Pi Power Consumption

#### Disable HDMI

1. Run `/usr/bin/tvservice -o`
1. Add `/usr/bin/tvservice -o` in `/etc/rc.local` to disable HDMI on boot

#### Turn Off LEDs

```
# The line below is used to turn off the power LED
sudo sh -c 'echo 0 > /sys/class/leds/led1/brightness'

# The line below is used to turn off the action LED
sudo sh -c 'echo 0 > /sys/class/leds/led0/brightness'
```

Add the following to the `/boot/config.txt`

```
# Disable Ethernet LEDs
dtparam=eth_led0=14
dtparam=eth_led1=14

# Disable the PWR LED
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off

# Disable the Activity LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
```

#### Disable Wifi

Add the following to the `/boot/config.txt`

```
# Disable Wifi
dtoverlay=pi3-disable-wifi
```

#### Disable Bluetooth

Add the following to the `/boot/config.txt`

```
# Disable Bluetooth
dtoverlay=pi3-disable-bt
```

## Manage it all from your mobile

[See original instructions](https://github.com/sebgl/htpc-download-box#manage-it-all-from-your-mobile)

## Going Further

[See original instructions](https://github.com/sebgl/htpc-download-box#going-further)


## Usefull Commands

```
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

docker logs --tail 50 --follow --timestamps transmission
docker exec -ti vpn bash

curl ifconfig.me
wget ifconfig.me

ncdu # excellent command-line disk usage analyser
df -h
```

## TODO

1. When Pi restart the env variables are not set anymore and with the container auto restart it's create issues (downloaded works, did VPN was on?)
1. Transmission seed config back to default after restart (seem to works now but not for `enable blocklist`)
1. Investigate why mount NTFS folder not working on startup (HDMI is off)
1. `Reduce Power Consumption` not working on startup
1. Transmission put completed download inside `complete/admin/torrent-folder-name`
1. For `fstab` what's diff with `auto,_netdev,nofaill`
1. Check why not working on Pi 1B+ (will never do it ...)
