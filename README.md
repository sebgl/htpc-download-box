# Pi HTPC Download Box

Sonarr / Radarr / Bazarr / Jackett / NZBGet / Transmission / Deluge / NordVPN / Plex

TV shows and movies download, sort, with the desired quality and subtitles, behind a VPN (optional), ready to watch, in a beautiful media player.
All automated.

## Table of Contents

- [Pi HTPC Download Box](#htpc-download-box)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Monitor TV shows/movies with Sonarr and Radarr](#overview)
    - [Search for releases automatically with Usenet and torrent indexers](#overview)
    - [Handle bittorrent and usenet downloads with Deluge and NZBGet](#overview)
    - [Organize libraries and play videos with Plex](#overview)
  - [Hardware configuration](#hardware-configuration)
  - [Software stack](#software-stack)
  - [Installation guide](#installation-guide)
    - [Introduction](#introduction)
    - [Hypriot OS](#hypriot-oS)
    - [Setup NTFS folder](#setup-ntfs-folder)
      - [Create NTFS folder on NAS](create-ntfs-folder-on-NAS)
      - [Mount NTFS folder on Pi](mount-ntfs-folder-on-Pi)
    - [Setup Transmission](#setup-transmission)
      - [Docker container](#docker-container)
      - [Configuration](#configuration)
    - [Setup Deluge](#setup-deluge)
      - [Docker container](#docker-container)
      - [Configuration](#configuration)
    - [Setup a VPN Container](#setup-a-vpn-container)
      - [Introduction](#introduction)
      - [Docker container](#docker-container)
    - [Setup Jackett](#setup-jackett)
    - [Setup NZBGet](#setup-nzbget)
    - [Setup Plex](#setup-plex)
    - [Setup Sonarr](#setup-sonarr)
    - [Setup Radarr](#setup-radarr)
    - [Setup Bazarr](#setup-bazarr)
      - [Remotly Add Movies Using trakt.tv And List](#remotly-add-movies-using-trakttv-and-list)
    - [Reduce Pi Power Consumption](#reduce-pi-power-consumption)
      - [Disable HDMI](#disable-hdmi)
      - [Turn Off LEDs](#turn-off-leds)
      - [Disable Wifi](#disable-wifi)
      - [Disable Bluetooth](#disable-bluetooth)
  - [Manage it all from your mobile](#manage-it-all-from-your-mobile)
  - [Going Further](#going-further)
  - [Usefull Commands](#usefull-commands)
  - [TODO](#todo)

## Overview

[See original instructions](https://github.com/sebgl/htpc-download-box#overview)

## Hardware configuration

I have a Synology DS2013j but it's too old to run sonarr/jackett/radarr/plex properly. The movies and tvshows will be stored in a NTFS folder on my nas, the softwares configurations will be stored in the PI. SQLlite doesn't like to be in a network folder, give a lot of `database locked` errors.

I use a Pi 3B but I have added the instructions for older Pi like the 1B and tested it but wasn't able to make it work.

![Error](img/raspberry_pi_1b_failure.png)

## Software stack

![Architecture Diagram](img/architecture_diagram.png)

**Downloaders**:

- [Transmission](https://transmissionbt.com/): torrent downloader with a web UI
- [Deluge](http://deluge-torrent.org/): torrent downloader with a web UI
- [NZBGet](https://nzbget.net): usenet downloader with a web UI
- [Jackett](https://github.com/Jackett/Jackett): API to search torrents from multiple indexers
- [Bazarr](https://www.bazarr.media/): A companion tool for Radarr and Sonarr which will automatically pull subtitles for all of your TV and movie downloads.

**Download orchestration**:

- [Sonarr](https://sonarr.tv): manage TV show, automatic downloads, sort & rename
- [Radarr](https://radarr.video): basically the same as Sonarr, but for movies

**VPN**:

- [NordVPN](https://nordvpn.com)

**Media Center**:

- [Plex](https://plex.tv): media center server with streaming transcoding features, useful plugins and a beautiful UI. Clients available for a lot of systems (Linux/OSX/Windows, Web, Android, Chromecast, Android TV, etc.)
- [Bazarr](https://www.bazarr.media): manage TV show and movies subtitles

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

### Setup environment variables

Instead of editing the docker-compose file to hardcode these values in, we'll instead put these values in a .env file. A .env file is a file for storing environment variables that can later be accessed in a general-purpose docker-compose.yml file, like the example one in this repository.

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

### Setup Yacht

#### Docker container

We'll use [Yacht](https://yacht.sh/) Docker image to monitor the other containers, it's an alternative to [Portainer](https://www.portainer.io/).

```yaml
yacht:
  container_name: yacht
  restart: unless-stopped
  ports:
    - 8000:8000
  volumes:
    - ${CONFIG}/config/yacht:/config
    - /var/run/docker.sock:/var/run/docker.sock
  image: selfhostedpro/yacht

volumes:
  yacht:
```

Things to notice:

- I use the host network to simplify configuration. The web ui is located on port `8000` (web UI).

Then run the container with `docker-compose up -d yacht`.
To follow container logs, run `docker-compose logs -f yacht`.

#### Configuration

You should be able to login on the web UI (`localhost:8000`, replace `localhost` by your machine ip if needed).

The default username is `admin@yacht.local` and password is `pass`.

### Setup Transmission

#### Docker container

We'll use Transmission Docker image from linuxserver, which runs both the Transmission daemon and web UI in a single container.
If you prefere Deluge just comment those lines in `docker-compose.yml`

```yaml
transmission:
  image: linuxserver/transmission:latest
  container_name: transmission
  restart: unless-stopped
  network_mode: service:vpn # run on the vpn network
  environment:
    - PUID=${PUID} # default user id, defined in .env
    - PGID=${PGID} # default group id, defined in .env
    - TZ=${TZ} # timezone, defined in .env
  volumes:
    - ${ROOT}/downloads:/downloads # downloads folder
    - ${CONFIG}/config/transmission:/config # config files
```

Things to notice:

- I use the host network to simplify configuration. Important ports are `9091` (web UI) and `51413` (bittorrent daemon).

Then run the container with `docker-compose up -d`.
To follow container logs, run `docker-compose logs -f transmission`.

#### Configuration

_instruction not updated for transmission but should be pretty much the same_

You should be able to login on the web UI (`localhost:9091`, replace `localhost` by your machine ip if needed).

The default password is `admin`. You are asked to modify it, I chose to set an empty one since transmission won't be accessible from outside my local network.

The running deluge daemon should be automatically detected and appear as online, you can connect to it.

You may want to change the download directory. I like to have to distinct directories for incomplete (ongoing) downloads, and complete (finished) ones.
Also, I set up a blackhole directory: every torrent file in there will be downloaded automatically. This is useful for Jackett manual searches.

You should activate `autoadd` in the plugins section: it adds supports for `.magnet` files.

You can also tweak queue settings, defaults are fairly small. Also you can decide to stop seeding after a certain ratio is reached. That will be useful for Sonarr, since Sonarr can only remove finished downloads from deluge when the torrent has stopped seeding. Setting a very low ratio is not very fair though !

Configuration gets stored automatically in your mounted volume (`${ROOT}/config/transmission`) to be re-used at container restart. Important files in there:

- `auth` contains your login/password
- `core.conf` contains your deluge configuration

You can use the Web UI manually to download any torrent from a .torrent file or magnet hash.

You should also add a [blacklist](https://giuliomac.wordpress.com/2014/02/19/best-blocklist-for-transmission/) for extra protection

### Setup Deluge

#### Docker container

We'll use Deluge Docker image from linuxserver, which runs both the Deluge daemon and web UI in a single container.
If you prefere Transmission just comment those lines in `docker-compose.yml`

```yaml
deluge:
  container_name: deluge
  image: linuxserver/deluge:latest
  restart: unless-stopped
  network_mode: service:vpn # run on the vpn network
  environment:
    - PUID=${PUID} # default user id, defined in .env
    - PGID=${PGID} # default group id, defined in .env
    - TZ=${TZ} # timezone, defined in .env
  volumes:
    - ${ROOT}/downloads:/downloads # downloads folder
    - ${CONFIG}/config/deluge:/config # config files
```

Things to notice:

- I use the host network to simplify configuration. Important ports are `8112` (web UI).

Then run the container with `docker-compose up -d`.
To follow container logs, run `docker-compose logs -f deluge`.

#### Configuration

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-deluge)

### Setup a VPN Container

#### Introduction

The goal here is to have an NordVPN Client container running and always connected. We'll make Transmission and/or Deluge incoming and outgoing traffic go through this NordVPN container.

This must come up with some safety features:

1. VPN connection should be restarted if not responsive
1. Traffic should be allowed through the VPN tunnel _only_, no leaky outgoing connection if the VPN is down
1. Transmission Web UI should still be reachable from the local network

#### Docker container

Put it in the docker-compose file, and make transmissionand/or Deluge use the vpn container network:

```yaml
vpn:
  container_name: vpn
  image: bubuntux/nordvpn:latest
  cap_add:
    - net_admin # required to modify network interfaces
  restart: unless-stopped
  devices:
    - /dev/net/tun
  environment:
    - USER=${VPN_USER} # vpn user, defined in .env
    - PASS=${VPN_PASSWORD} # vpn password, defined in .env
    - COUNTRY=${VPN_COUNTRY} # vpn country, defined in .env
    - NETWORK=${NETWORK} # local network mask, defined in .env
    - PROTOCOL=UDP
    - CATEGORY=P2P
    - OPENVPN_OPTS=--pull-filter ignore "ping-restart" --ping-exit 180
    - TZ=${TZ} # timezone, defined in .env
  ports:
    - 9091:9091 # Transmission web UI
    - 51413:51413 # Transmission bittorrent daemon
    - 51413:51413/udp # Transmission bittorrent daemon
    - 8112:8112 # port for deluge web UI to be reachable from local network

transmission:
  image: linuxserver/transmission:latest
  container_name: transmission
  restart: unless-stopped
  network_mode: service:vpn # run on the vpn network
  environment:
    - PUID=${PUID} # default user id, defined in .env
    - PGID=${PGID} # default group id, defined in .env
    - TZ=${TZ} # timezone, defined in .env
  volumes:
    - ${ROOT}/downloads:/downloads # downloads folder
    - ${CONFIG}/config/transmission:/config # config files

deluge:
  container_name: deluge
  image: linuxserver/deluge:latest
  restart: unless-stopped
  network_mode: service:vpn # run on the vpn network
  environment:
    - PUID=${PUID} # default user id, defined in .env
    - PGID=${PGID} # default group id, defined in .env
    - TZ=${TZ} # timezone, defined in .env
  volumes:
    - ${ROOT}/downloads:/downloads # downloads folder
    - ${CONFIG}/config/deluge:/config # config files
```

Notice how transmission and/or Deluge is now using the vpn container network, with Transmission and/or Deluge web UI port exposed on the vpn container for local network access.

You can check that Transmission and/or Deluge is properly going out through the VPN IP by using [torguard check](https://torguard.net/checkmytorrentipaddress.php).
Get the torrent magnet link there, put it in Transmission and/or Deluge, wait a bit, then you should see your outgoing torrent IP on the website.

![Torrent guard](img/torrent_guard.png)

### Setup Jackett

#### Indexers

1. 1337x
1. cpasbien (always failed)
1. RARBG
1. The Pirate Bay
1. LimeTorrents
1. Torrent9
1. Torrentz2

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-jackett)

### Setup NZBGet

Uncomment container instructions in `docker.compose.yml`

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-nzbget)

### Setup Plex

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-plex)

### Setup Sonarr

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-sonarr)

### Setup Radarr

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-radarr)

### Setup Bazarr

[See original instructions](https://github.com/sebgl/htpc-download-box#setup-bazarr)

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
