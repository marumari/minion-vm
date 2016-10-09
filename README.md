# minion-vm
Vagrantfile and Dockerfiles to make developing against [Mozilla Minion](https://github.com/mozilla/minion) far easier.

**minion-vm** automatically installs the following Minion components:
* https://github.com/mozilla/minion-backend
* https://github.com/mozilla/minion-frontend
* https://github.com/mozilla/minion-nmap-plugin

Configuring minion-vm
---------------------
Prior to installation, it is necessary to set the default administrator's email address and name:

**Vagrantfile**
```
## Set these to ensure administrative rights when the backend is provisioned.
MINION_ADMINISTRATOR_NAME = "April King"
MINION_ADMINISTRATOR_EMAIL = "april@mozilla.com"
```

**docker-compose.yml**
```
services:
  backend:
    ...
    environment:
      - MINION_ADMINISTRATOR_EMAIL="youremail@yourorganization.org"
      - MINION_ADMINISTRATOR_NAME="Your Name Here"
```

**If you're not using Docker Compose, see below for building the container with these arguments**


Configuring Vagrant
-------------------
* Edit the BACKEND\_SRC, FRONTEND\_SRC, and APT\_CACHE\_SRC variables in `Vagrantfile` to point to their locations on your local system
* Edit the IP addresses in `Vagrantfile` and `vagrant-hosts.sh` if you want your private network to use something besides 192.168.50.49 and 192.168.50.50

Running Vagrant
---------------
```
$ vagrant up
```

That's it! The Minion frontend should now be accessible at http://192.168.50.50:8080, or whatever you set the IP address to.

You can also ssh into your new Minion instances with `vagrant ssh minion-frontend` and `vagrant ssh minion-backend`.

Configuring Docker
------------------
You'll need to specify [build args](https://docs.docker.com/engine/reference/commandline/build/) when building the containers so that MINION_ADMINISTRATOR_NAME and MINION_ADMINISTRATOR_EMAIL are
properly set.  **If you're using docker-compose, you can skip building the containers this way**

*[For example](https://docs.docker.com/engine/reference/commandline/build/#/set-build-time-variables---build-arg)*
```
$ docker build \
  -t 'mozilla/minion-backend' \
  -f Dockerfile-backend \
  --build-arg MINION_ADMINISTRATOR_NAME={your name here} \
  --build-arg MINION_ADMINISTRATOR_EMAIL={your email here} \
  .
$ docker build -t 'mozilla/minion-frontend' -f Dockerfile-frontend .
```


Running Docker
--------------
Running the containers individually

```
$ docker run -d --name 'minion-backend' 'mozilla/minion-backend'
$ docker run -d -p 8080:8080 --name 'minion-frontend' \
    --link minion-backend:minion-backend 'mozilla/minion-frontend'
```

**OR**

Running the containers with Compose
```
$ docker-compose up -d
```

The Minion frontend should now be accessible over HTTP at the IP address of the system running Docker, on port 8080.

You can also get a shell on your new Minion instances with `docker exec -i -t minion-frontend /bin/bash` and
`docker exec -i -t minion-backend /bin/bash`.
