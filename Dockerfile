FROM ubuntu:18.04
MAINTAINER ffdixon@bigbluebutton.org

ENV DEBIAN_FRONTEND noninteractive
ENV container docker

RUN apt-get update && apt-get install  -y netcat

# -- Test if we have apt cache running on docker host, if yes, use it.
# RUN nc -zv host.docker.internal 3142 &> /dev/null && echo 'Acquire::http::Proxy "http://host.docker.internal:3142";'  > /etc/apt/apt.conf.d/01proxy

# -- Install utils
RUN apt-get update && apt-get install -y wget apt-transport-https

RUN apt-get install -y language-pack-en
RUN update-locale LANG=en_US.UTF-8

# -- Install system utils
RUN apt-get update 
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y wget software-properties-common

# -- Install yq 
RUN LC_CTYPE=C.UTF-8 add-apt-repository ppa:rmescandon/yq
RUN apt update
RUN LC_CTYPE=C.UTF-8 apt install yq -y

# -- Setup tomcat to run under docker
RUN apt-get install -y \
  haveged    \
  net-tools  \
  supervisor \
  sudo       \
  tomcat8

# -- Modify systemd to be able to run inside container
RUN apt-get update \
    && apt-get install -y systemd

# -- Install Dependencies
RUN apt-get install -y mlocate strace iputils-ping telnet tcpdump vim htop

# -- Install nginx (in order to enable it - to avoid the "nginx.service is not active" error)
RUN apt-get install -y nginx
RUN systemctl enable nginx

# -- Disable unneeded services
RUN systemctl disable systemd-journal-flush
RUN systemctl disable systemd-update-utmp.service

# -- Install redis (in order to change bind ip before bbb-install)
RUN apt-get install -y redis-server

# -- Finish startup 
#    Add a number there to force update of files on build
RUN echo "Finishing ... @15"
RUN mkdir /opt/docker-bbb/
RUN wget ./install.sh -O- | sed 's|https://\$PACKAGE_REPOSITORY|http://\$PACKAGE_REPOSITORY|g' > /opt/docker-bbb/bbb-install.sh
RUN chmod 755 /opt/docker-bbb/bbb-install.sh
ADD setup.sh /opt/docker-bbb/setup.sh
ADD rc.local /etc/
RUN chmod 755 /etc/rc.local

ADD haveged.service /etc/systemd/system/default.target.wants/haveged.service

ENTRYPOINT ["/bin/systemd", "--system", "--unit=multi-user.target"]
CMD []

