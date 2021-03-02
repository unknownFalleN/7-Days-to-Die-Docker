######## INSTALL ########

# Set the base image
FROM ubuntu:18.04

# ENV
ARG PUID=1000
ARG PGID=1000
ENV PUID=$PUID
ENV PGID=$PGID
ENV USER=steam
ENV WORKDIR=/app
ENV TZ=Europe/Berlin
ENV SEVEN_DAYS_TO_DIE_BETA=0
ENV SEVEN_DAYS_TO_DIE_TELNET_PORT=8081
ENV SEVEN_DAYS_TO_DIE_TELNET_PASSWORD=""
ENV SEVEN_DAYS_TO_DIE_START_MODE=3
ENV SEVEN_DAYS_TO_DIE_SERVER_STARTUP_ARGUMENTS="-quit -batchmode -nographics -dedicated"

# Labels
LABEL maintainer="rodsec"
LABEL version="1.0.0"
LABEL description="7 Days to Die Server"

# Insert Steam prompt answers
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections

# Update the repository and install SteamCMD
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    locales \
    steamcmd \
    expect \
    telnet \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir ${WORKDIR} 

# Create symlink for executable, user and permission, add unicode support and set timezone
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd \
 && locale-gen en_US.UTF-8 \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} > /etc/timezone \
 && groupadd -g ${PGID} -r ${USER} \
 && useradd -d ${WORKDIR}/${USER} -u ${PUID} -g ${USER} -m ${USER}

ENV LANG 'en_US.UTF-8'
ENV LANGUAGE 'en_US:en'

COPY shutdown.sh ${WORKDIR}/${USER}/shutdown.sh
COPY docker-entrypoint.sh ${WORKDIR}/${USER}/docker-entrypoint.sh

RUN mkdir -p "${WORKDIR}/${USER}/.local/share/7DaysToDie/Saves" \
    "${WORKDIR}/${USER}/sdtd/config/" \
    "${WORKDIR}/${USER}/.steam/steam/steamapps/common/7 Days To Die/Mods"

# Change permissions to $USER
RUN chown -R ${USER}:${USER} \
    ${WORKDIR}/${USER}/ \
 && chmod u+x ${WORKDIR}/${USER}/docker-entrypoint.sh \
    ${WORKDIR}/${USER}/shutdown.sh

USER ${USER}
WORKDIR ${WORKDIR}/${USER}

#Ports
EXPOSE 26900 26900/UDP 26901/UDP 26902/UDP 8081

#Shared folders to host
VOLUME [ \
    "${WORKDIR}/${USER}/sdtd/config/", \
    "${WORKDIR}/${USER}/.local/share/7DaysToDie/Saves",  \
    "${WORKDIR}/${USER}/.steam/steam/steamapps/common/7 Days To Die/Mods" \
    ]

# Set default command
ENTRYPOINT ["./docker-entrypoint.sh"]