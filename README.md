# Docker image for SimpleSAMLPHP

A docker image based on PHP-FPM-Alpine for a quick SimpleSAML setup with a set of pre-activated modules. It requires a webserver instance to access the web admin pages. Recommend to use in combination with the [stvfccn/nginx_proxy](https://hub.docker.com/r/stvfccn/nginx_proxy) docker image as the webserver.

The following is used in this image:
- PHP 7.3 (FPM)
- SimpleSAML 1.17.4 with the following modules activated:
  - metarefresh
  - cron
  - exampleauth
  - advancedauthfilters

## Requirements

To build this container you need to have docker installed. A makefile is provided along with the project to facilitate
building and publishing of the images. Image available in docker hub [stvfccn/simplesamlphp](https://hub.docker.com/r/stvfccn/simplesamlphp)

## Configure and Install

Check the **deploy.env** file for build configurations for both the production and development images. To publish the image you will
need to change the **DOCKER_REPO** var to your repository location. This can also be a private repository location.

## Building the docker image

To create the image run:
```
make image
```

To create and publish a new version of the image run:
```
make release
```

For more information on what it is possible to do

```
make help
```

## Usage

To correctly use this image along with a web server the following is required:

- You can use a web server image to serve the web content.
- You need to define the site configuration on the sites-enabled folder located under **$NGINX_OPTS/sites-enabled**, check *test/config/sites-enabled* for examples.
- Import the html content to the root folder defined in the site settings.
- The container entrypoint script needs to be executed by root. The entrypoint script starts and monitors the required processes for the webserver.

To check the sample site provided with this project run:

```
$ make test
```
You can then access the test page at http://localhost:10080 (if defaults are being used)

Alternatively, create an application specific Dockerfile to generate a new image that includes the necessary content and additional configurations:

```
FROM stvfccn/nginx_proxy

#--- additional NGINX general configurations
COPY config/my-nginx-general-settings.conf $NGINX_OPTS/conf.d/90-general-configs.conf

#--- NGINX site configuration
COPY config/my-site-settings.conf $NGINX_OPTS/sites-enabled/my-site-settings.conf

USER application

#--- copy application contents
WORKDIR $WEB_DOCUMENT_ROOT
COPY my-site-contents .

# run this container as root because of entrypoint script or replace with new entrypoint
USER root

```

### Usage with docker-compose

Use the following sample compose file to start this container in docker-compose:

```yaml
version: '3.4'
services:

  nginx:
    image: stvfccn/nginx_proxy
    container_name: nginx_proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./sites-enabled:/opt/nginx/sites-enabled   # site configurations
      - ./conf.d:/opt/nginx/conf.d                 # additional nginx configs
      - ./certs:/opt/nginx/ssl                     # ssl certificates
      - ./webcontent:/var/www                      # html static content
    - simplesamldata:/var/simplesaml			   # simplesaml root folder volume
      - simplesamlopts:/opt/simplesaml			   # simplesaml configs folder volume

  simplesaml:
    image: stvfccn/simplesamlphp
    volumes:
      - simplesamldata:/var/simplesaml			   # simplesaml root folder volume
      - simplesamlopts:/opt/simplesaml 			   # simplesaml configs folder volume

volumes:
  simplesamldata:
    name: simplesaml_data
  simplesamlopts:
    # make sure to preserve saml configs locally
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/opt/webserver/simplesaml'
    name: simplesaml_opts

```

In the example above the site configurations are defined in **sites-enabled** folder, additional nginx configurations can be set on the **conf.d** folder, the ssl certificates are located in the **certs** folder and the html static content at the **webcontent** folder.

## Author

Paulo Costa

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/fccn/docker-npn-webapp-base/tags).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
