# Setup a VPN Container

## Introduction

The goal here is to have an OpenVPN Client container running and always connected. We'll make Deluge incoming and outgoing traffic go through this OpenVPN container.

This must come up with some safety features:

1. VPN connection should be restarted if not responsive
1. Traffic should be allowed through the VPN tunnel _only_, no leaky outgoing connection if the VPN is down
1. Deluge Web UI should still be reachable from the local network

Lucky me, someone already [set that up quite nicely](https://github.com/dperson/openvpn-client).

Point 1 is resolved through the OpenVPN configuration (`ping-restart` set to 120 sec by default).
Point 2 is resolved through [iptables rules](https://github.com/dperson/openvpn-client/blob/master/openvpn.sh#L52-L87)
Point 3 is also resolved through [iptables rules](https://github.com/dperson/openvpn-client/blob/master/openvpn.sh#L104)

Configuration is explained on the [project page](https://github.com/dperson/openvpn-client), you can follow it.
However it is not that easy depending on your VPN server settings.
I'm using a privateinternetaccess.com VPN, so here is how I set it up.

## PIA Custom Setup

_Note_: this section only applies for [PIA](https://privateinternetaccess.com) accounts.

Download PIA OpenVPN [configuration files](https://privateinternetaccess.com/openvpn/openvpn.zip).
In the archive, you'll find a bunch of `<country>.ovpn` files, along with 2 other important files: `crl.rsa.2048.pem` and `ca.rsa.2048.crt`. Pick the file associated to the country you'd like to connect to, for example `netherlands.ovpn`.

Copy the 3 files to `${ROOT}/config/vpn`.
Create a 4th file `vpn.auth` with the following content:

```Text
<pia username>
<pia password>
```

You should now have 3 files in `${ROOT}/config/vpn`:

- netherlands.ovpn
- vpn.auth
- crl.rsa.2048.pem
- ca.rsa.2048.crt

Edit `netherlands.ovpn` (or any other country of your choice) to tweak a few things (see my comments on lines added or modified):

```INI
client
dev tun
proto udp
remote nl.privateinternetaccess.com 1198
resolv-retry infinite
nobind
persist-key
# persist-tun # disable to completely reset vpn connection on failure
cipher aes-128-cbc
auth sha1
tls-client
remote-cert-tls server
auth-user-pass /vpn/vpn.auth # to be reachable inside the container
comp-lzo
verb 1
reneg-sec 0
crl-verify /vpn/crl.rsa.2048.pem # to be reachable inside the container
ca /vpn/ca.rsa.2048.crt # to be reachable inside the container
disable-occ
keepalive 10 30 # send a ping every 10 sec and reconnect after 30 sec of unsuccessfull pings
pull-filter ignore "auth-token" # fix PIA reconnection auth error that may occur every 8 hours
```

Then, rename `<country>.ovpn` to `vpn.conf`

## Docker container

Put it in the docker-compose file, and make deluge use the vpn container network:

```yaml
vpn:
  container_name: vpn
  image: dperson/openvpn-client:latest
  cap_add:
    - net_admin # required to modify network interfaces
  restart: unless-stopped
  volumes:
    - /dev/net:/dev/net:z # tun device
    - ${ROOT}/config/vpn:/vpn # OpenVPN configuration
  security_opt:
    - label:disable
  ports:
    - 8112:8112 # port for deluge web UI to be reachable from local network
  command: '-r 192.168.1.0/24' # route local network traffic
  labels:
    - 'traefik.backend=vpn'
    - 'traefik.local.frontend.rule=Host:deluge.localhost'
    - 'traefik.port=8112'
    - 'traefik.enable=true'
```

Notice how the labels forward to `deluge.localhost` to access this container. This is because Deluge will be routed through the `vpn` container to make sure that all traffic is protected.
