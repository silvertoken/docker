FROM centos:latest

MAINTAINER silvertoken <silvertoken99@gmail.com>

# Upate image and install Oracle JRE 8
RUN yum update -y && yum install -y \
    cronie \
	unzip \
	wget && \
    wget --no-cookies --no-check-certificate \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jre-8u102-linux-x64.rpm" && \
    yum localinstall -y /jre-8u102-linux-x64.rpm && \
    rm -f /jre-8u102-linux-x64.rpm && \
    yum clean all
	
RUN useradd -M -s /bin/false --uid 1000 minecraft \
  && mkdir -p /opt/minecraft/data \
  && mkdir -p /opt/minecraft/config \
  && mkdir -p /opt/minecraft/mods \
  && mkdir -p /opt/minecraft/plugins \
  && mkdir -p /opt/minecraft/backups \
  && chown minecraft:minecraft -R /opt/minecraft

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

#expose the mc port
EXPOSE 25565 25575

COPY start.sh /start
COPY start-minecraft.sh /start-minecraft

VOLUME ["/opt/minecraft/data","/opt/minecraft/mods","/opt/minecraft/config","/opt/minecraft/plugins","/opt/minecraft/backups"]
COPY server.properties /tmp/server.properties
WORKDIR /opt/minecraft/data

ENTRYPOINT [ "/start" ]

ENV UID=1000 GID=1000 \
    MOTD="A Minecraft Server Powered by Docker" \
    JVM_OPTS="-Xmx1024M -Xms1024M" \
    TYPE=VANILLA VERSION=LATEST FORGEVERSION=RECOMMENDED LEVEL=world PVP=true DIFFICULTY=easy \
    LEVEL_TYPE=DEFAULT GENERATOR_SETTINGS= WORLD= MODPACK=