# List of containers that can be interesting to add

## Grafana

```
grafana:
    container_name: grafana
    image: grafana/grafana:latest
    # user: "999"
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=${TZ} # timezone, defined in .env
      - GF_SERVER_ROOT_URL:http://metis.local
      - GF_INSTALL_PLUGINS="grafana-clock-panel,grafana-simple-json-datasource,andig-darksky-datasource,grafana-piechart-panel"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./grafana:/var/lib/grafana
    ports:
      - 3000:3000
```

## Traefik

```
  traefik:
    container_name: traefik
    image: arm64v8/traefik:alpine
    restart: unless-stopped
    networks:
      - default
      - traefik_proxy
    depends_on:
      - deluge
      - nzbget
      - sonarr
      - radarr
      - jackett
#      - portainer
    ports:
      - "6660:6660"
      - "6661:6661"
      - "8080:8080"
    domainname: ${DOMAINNAME}
    environment:
      - TZ=${TZ} # timezone
      - PUID=${PUID} # default user id, for downloaded files access rights
      - PGID=${PGID} # default group id, for downloaded files access rights
      - DOMAINNAME=${DOMAINNAME}
      - CLOUDFLARE_EMAIL=jasonbhart@gmail.com
      - CLOUDFLARE_API_KEY=4f326d3ccb01ede7180bf0ef1287aee7b220a
    volumes:
      - /media/usb1/.config/traefik:/etc/traefik # config files
      - /var/run/docker.sock:/var/run/docker.sock
    labels:
      - "traefik.enable=true"
      - "traefik.backend=traefik"
      - "traefik.frontend.rule=Host:traefik.${DOMAINNAME}"
      - "traefik.port=8080"
      - "traefik.docker.network=traefik_proxy"
      - "traefik.frontend.headers.SSLRedirect=true"
      - "traefik.frontend.headers.STSSeconds=315360000"
      - "traefik.frontend.headers.browserXSSFilter=true"
      - "traefik.frontend.headers.contentTypeNosniff=true"
      - "traefik.frontend.headers.forceSTSHeader=true"
      - "traefik.frontend.headers.SSLHost=${DOMAINNAME}"
      - "traefik.frontend.headers.STSIncludeSubdomains=true"
      - "traefik.frontend.headers.STSPreload=true"
      - "traefik.frontend.headers.frameDeny=true"

networks:
  traefik_proxy:
    external:
      name: traefik_proxy
  default:
    driver: bridge

```

## Portainer

```
  portainer:
    container_name: portainer
    image: portainer/portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock
    ports:
      - "9000:9000"
    networks:
      - traefik_proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    environment:
      - TZ=${TZ}
    labels:
      - "traefik.enable=true"
      - "traefik.backend=portainer"
      - "traefik.frontend.rule=Host:portainer.${DOMAINNAME}"
      - "traefik.port=9000"
      - "traefik.docker.network=traefik_proxy"
      - "traefik.frontend.headers.SSLRedirect=true"
      - "traefik.frontend.headers.STSSeconds=315360000"
      - "traefik.frontend.headers.browserXSSFilter=true"
      - "traefik.frontend.headers.contentTypeNosniff=true"
      - "traefik.frontend.headers.forceSTSHeader=true"
      - "traefik.frontend.headers.SSLHost=${DOMAINNAME}"
      - "traefik.frontend.headers.STSIncludeSubdomains=true"
      - "traefik.frontend.headers.STSPreload=true"
      - "traefik.frontend.headers.frameDeny=true"
      
volumes:
  portainer_data:
```
