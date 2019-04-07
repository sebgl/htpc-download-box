# Setup NZBGet

## Docker container

Once again we'll use the Docker image from linuxserver and set it in a docker-compose file.

```yaml
nzbget:
  container_name: nzbget
  image: linuxserver/nzbget:latest
  restart: unless-stopped
  expose:
    - '6789'
  environment:
    - PUID=${PUID} # default user id, defined in .env
    - PGID=${PGID} # default group id, defined in .env
    - TZ=${TZ} # timezone, defined in .env
  volumes:
    - ${ROOT}/downloads:/downloads # download folder
    - ${ROOT}/config/nzbget:/config # config files
  labels:
    - 'traefik.backend=nzbget'
    - 'traefik.local.frontend.rule=Host:nzbget.localhost'
    - 'traefik.port=6789'
    - 'traefik.enable=true'
```

## Configuration and usage

After running the container, web UI should be available on `nzbget.localhost`.
Username: nzbget
Password: tegbzn6789

![NZBGet](img/nzbget_empty.png)

Since NZBGet stays on my local network, I choose to disable passwords (`Settings/Security/ControlPassword` set to empty).

The important thing to configure is the url and credentials of your newsgroups server (`Settings/News-servers`). I have a Frugal Usenet account at the moment, I set it up with TLS encryption enabled.

Default configuration suits me well, but don't hesitate to have a look at the `Paths` configuration.

You can manually add .nzb files to download, but the goal is of course to have Sonarr and Radarr take care of it automatically.
