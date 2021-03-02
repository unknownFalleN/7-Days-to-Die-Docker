#!/usr/bin/env bash

# Enable debugging
# set -eu

# Parameter
APP_ID="294420"
STEAM_CMD_PARAMETER="+Login anonymous +@sSteamCmdForcePlatformType linux +force_install_dir ${WORKDIR}/${USER}/sdtd"

## Checking free space
check_space()
{
    echo "Checking free space ..."
    free=$(df -k --output=avail "${WORKDIR}" | tail -n1)
    freeGB=$((free / 1024 / 1024))
    if [[ ${free} -lt 12582912 ]]; then  # 12G = 12*1024*1024k
        echo "ERROR: Not enough space to install Game"
        echo "Needed: 12 GB"
        echo "Available: ${freeGB} GB"
        echo "Exit script..."
        exit 1
    else
        echo "Enough space ${freeGB} GB available. Continue installation ..."
    fi
}

# Signal handler for stoping container
signal_handler()
{
    echo "Shutdown signal received.."

    # Execute the telnet shutdown commands
    "${WORKDIR}/${USER}/shutdown.sh"
    signal=$!
    wait "$signal"

    sleep 4

    echo "Exiting.."
    exit 0
}

start_sdtd()
{
    echo ""
    echo "Starting 7 Days To Die Server as user $(whoami)..."
    echo ""
    # 7 Days to Die 64-bit version of steamclient.so
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${WORKDIR}/${USER}/sdtd/7DaysToDieServer_Data/Plugins/x86_64
    "${WORKDIR}/${USER}/sdtd/7DaysToDieServer.x86_64" "${SEVEN_DAYS_TO_DIE_SERVER_STARTUP_ARGUMENTS}" -configfile="${WORKDIR}/${USER}/sdtd/config/serverconfig.xml" &
    child=$!
    wait "${child}"
}

start_steamcmd()
{   
    echo ""
    echo "Install steamcmd app. This will take a few minutes ..."
    echo ""
    steamcmd "${STEAM_CMD_PARAMETER}" +app_update "${APP_ID}" "${SEVEN_DAYS_TO_DIE_BRANCH}" -validate +quit
    echo ""
    echo "Finished install app 7 Days to Die."
    echo ""
    # Validate that the default server configuration file exists
    if [ ! -f "${WORKDIR}/${USER}/sdtd/serverconfig.xml" ]; then
        echo "ERROR: Default server configuration file not found, are you sure the server is up to date?"
        exit 1
    else
        if [ ! -f "${WORKDIR}/${USER}/sdtd/config/serverconfig.xml" ]; then
            echo ""
            echo "No serverconfig available. Copy default serverconfig to shared docker volume."
            echo ""
            cp "${WORKDIR}/${USER}/sdtd/serverconfig.xml" "${WORKDIR}/${USER}/sdtd/config/serverconfig.xml"
        else
            echo ""
            echo "Changing 7 Days to Die Serverconfig"
            echo ""
            # ToDo sed
        fi
    fi
}

#
# Main
#
# TODO Docker Stop Signal-Handling
# Todo Checke Telnet Port sed

# checking steamcmd installed
command -v steamcmd >/dev/null 2>&1 || { echo >&2 "I require steamcmd but it's not installed.  Aborting."; exit 1; }

# Print the user we're currently running as
echo "Running as user: $(whoami)"

child=0

# checking free space
check_space

# Trap specific signals and forward to the exit handler
trap 'signal_handler' SIGINT SIGTERM

SEVEN_DAYS_TO_DIE_BRANCH=""
if [ "${SEVEN_DAYS_TO_DIE_BETA}" == 1 ]
then
    SEVEN_DAYS_TO_DIE_BRANCH="-beta latest_experimental"
fi

case $SEVEN_DAYS_TO_DIE_START_MODE in
     0)
        steamcmd --help
     ;;
     1)
        ## Start
        # TODO Check install 
        start_sdtd
     ;;
     2)
        # Update
        start_steamcmd
     ;;
     3)
        # Update & Start
        start_steamcmd
        start_sdtd
     ;; 
     *)
        # 
        steamcmd --help
     ;;
  esac
