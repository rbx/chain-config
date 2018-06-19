#! /usr/bin/env bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color

export ALIBUILD_WORK_DIR=$HOME/dev/alice/sw # MODIFY ME

printf "\n${GREEN}entering O2/latest environment with alienv...${NC}\n\n"
printf "###############################################\n"
eval `$HOME/.local/bin/alienv --no-refresh load O2/latest`
printf "###############################################\n"

alienv list

topologyFile="$HOME/dev/alice/topology.xml"
requiredNofAgents=63

# Source DDS environment
printf "\n${GREEN}Initializing DDS environment (from ${NC}$DDS_ROOT${GREEN})...${NC}"
source $DDS_ROOT/DDS_env.sh

printf "\n\n${GREEN}Located dds-server:${NC} "

which dds-server

printf "\n\n"

# Start DDS commander server
printf "Starting DDS server...\n"
startOutput=$(dds-server start -s)
printf "${startOutput}\n"

# Extract session ID from "dds-server start" output
sessionID=$(echo -e "${startOutput}" | head -1 | awk '{split($0,a,":"); print a[2]}' | tr -d '[:space:]')
printf "DDS session ID: ${sessionID}\n"

# Submit agents
printf "Submiting agents..."
dds-submit --rms ssh --config $HOME/dev/alice/hosts.cfg --session ${sessionID}

# Waiting for DDS agents.
# Give DDS agents 20 seconds to start.
counter=0
nofAgents=$(dds-info -n --session ${sessionID})
while [ ${nofAgents} -lt ${requiredNofAgents} ]; do
	nofAgents=$(dds-info -n --session ${sessionID})
        printf "number of agents: ${nofAgents}/${requiredNofAgents}"
    let counter=counter+1
    if [ ${counter} -gt 20 ]; then
      printf "Error: not enough agents"
      exit 1
    fi
    sleep 1
done

printf "successfully waited for ${requiredNofAgents} agents."

# # Activate topology
# printf "Activating topology..."
# dds-topology --disable-validation --session ${sessionID} --activate ${topologyFile}

# # FIXME: Implement proper waiting
# sleep 60

sleep 5

# FIXME: Implement proper check of the results

# Stop DDS commander
printf "Stoping server..."
dds-server stop ${sessionID}

printf "${GREEN}leaving O2/latest environment with alienv...\n\n${NC}"
printf "###############################################\n"
eval `$HOME/.local/bin/alienv --no-refresh unload O2/latest`
printf "###############################################\n"

exit 0

