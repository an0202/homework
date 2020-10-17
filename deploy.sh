#!/bin/bash
#
# Constant
readonly JENKINS_SERVER="http://172.17.0.1:8080"
readonly API_USER="thoughtworks"
readonly API_TOKEN="1129a3c26f97eaf53164274d6fd40d366c"
readonly SERVICE_PATH="/data/homework_anjie/jenkins_home/tools/service"
# Function
# deploy
function deploy {
    local job_name="$1"
    local src_path="$2"
    local dest_name="$3"
    if [[ $# == 3 ]] ;then
        # Source file check, copy
        if [[ "${src_path##*.}"x = "war"x ]]||[[ "${src_path##*.}"x = "zip"x ]];then
           cp -f ${src_path} ${SERVICE_PATH}/${job_name}/${dest_name}
            if [[ "$?" -ne 0 ]]; then
                echo "[Error] File copy failed"
            exit 1
        fi
        else
            echo "[error] Source file must be .zip or .war"
            exit 2
        fi
        # Trigger jenkins deploy api
        curl ${JENKINS_SERVER}/job/${job_name}/buildWithParameters \
            --user ${API_USER}:${API_TOKEN} \
            --data Action=Deploy
        echo "[info]Deploy new job for ${job_name} in-progress ,check jenkins server for more details!"
    else
        usage
        exit 1
    fi
}

# rollback_last
function rollback_last {
    local job_name="$1"
    if [[ $# == 1 ]] ;then
        # Trigger jenkins deploy api
        curl ${JENKINS_SERVER}/job/${job_name}/buildWithParameters \
            --user ${API_USER}:${API_TOKEN} \
            --data Action=Rollback
        echo "[info]Rollback last version for ${job_name} in-progress ,check jenkins server for more details!"
    else
        usage
        exit 1
    fi
}

# Usage
function usage {
    echo "### The script needs to be run on the host where Jenkins is located"
    echo "$0 deploy job_name src_path dest_name  -- 'Deploy a new specific job"
    echo "$0 rollback job_name -- 'Rollback a specific job to last version'"
    exit 0
}

#
function main {
    local action="$1"
    local job_name="$2"
    local src_path="$3"
    local dest_name="$4"
    case "${action}" in
    "deploy")
    deploy ${job_name} ${src_path} ${dest_name}
    ;;
    "rollback")
    rollback_last ${job_name}
    ;;
    *)
    usage
    exit 0
    ;;
    esac
}

#main
main $@
