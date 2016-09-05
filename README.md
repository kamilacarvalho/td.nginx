# td.nginx
This is an nginx reverse proxy designed to front microservices with HTTPS, using [letsencrypt](https://letsencrypt.org/).

## Automatic certificate generation
When the container boots, if no certificates are found, it will do the following:

  - First create a self signed certificate for the domain in question (so we can start nginx, and letsencrypt can do it's host checks).
  - Use [simp_le](https://github.com/kuba/simp_le) to generate, or update the letsencrypt certificates for the domain.

## Multiple domains, no configuration
All this container needs to run is some environmental configuration, no nginx configuration.  Take the following docker-compose.yml.  In this example we have two microservices, gateway and dashboard, listening on 9000 and 9001 respectively.  We define two environment variables, one for each host, with the `FQDN` we want, as well as the `upstream`, and then `default_server`.

The default server part is important, as we're hosting multiple SSL certificates on the same IP, Nginx will use [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) to serve up the relevant endpoint.  If the client doesn't support SNI (for example, my curl client on macosx?!) then you'll get the default server. 

```
version: '2'

networks:
  frontplane:

services:
  td.nginx:
    image: eu.gcr.io/peopledata-product-team/td.nginx
    restart: always
    networks:
      frontplane:
        aliases:
          - gateway
          - dashboard
    environment:
      - HOST_GATEWAY=gateway.thoughtdata.thoughtworks.net,gateway:9000,default_server
      - HOST_DASHBOARD=dashboard.thoughtdata.thoughtworks.net,dashboard:9001
    ports:
      - 443
      - 80
```
