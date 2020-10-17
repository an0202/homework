#!/bin/bash
#
# Constant
export ANSIBLE_HOST_KEY_CHECKING=False
#readonly BASE_PATH=$(dirname "$PWD")
readonly BASE_PATH="/var/jenkins_home/tools"
readonly INVENTORY_PATH=${BASE_PATH}/inventory
readonly VERSION_PATH=${BASE_PATH}/version
readonly PLAYBOOK_PATH=${BASE_PATH}/playbook
# Function
function check_version_file {
    local job_name="$1"
    if [[ $# != 1 ]]; then
        echo "[Error] Missing Job Name"
        exit 1
    fi
    if [[ ! -f ${VERSION_PATH}/${job_name} ]];then
    echo "[INFO] First Deployment For ${job_name}"
        cat << _EOF > ${VERSION_PATH}/${job_name}
#
CurrentVersion=
#
LastVersion=
_EOF
    fi
}
#
function build {
    local job_name="$1"
    local version="$2"
    # deploy
    ansible-playbook -i ${INVENTORY_PATH}/${JOB_NAME} \
        ${PLAYBOOK_PATH}/base.yaml -e job_name=${job_name} -e version=${version} --tags "login,build"
    if [[ "$?" -ne 0 ]]; then
    echo "[Error] Build Failed"
    exit 2
    fi
}
#
function deploy {
    local job_name="$1"
    local version="$2"
    local host="$3"
    if [[ $# == 3 ]] ;then
        #deploy
        ansible-playbook -i ${INVENTORY_PATH}/${JOB_NAME} \
            ${PLAYBOOK_PATH}/${job_name}.yaml -e hosts_group=${host} -e job_name=${job_name} -e version=${job_name}-${version} --tags "stop,start"
        if [[ "$?" -ne 0 ]]; then
        echo "[Error] Deploy Failed"
        exit 1
        fi
    else
        echo "[Error] Missing JobName Or Version"
        exit 1
    fi
    # change version record
    version_file=${VERSION_PATH}/${job_name}
    old_version=$(awk -F "=" 'NR==2&&match($0,'CurrentVersion') {print $2}' ${version_file})
    release_version=${job_name}-${version}
    if [[ ${old_version} != ${release_version} ]];then
        # set new currentVersion
        sed -ri "s/(CurrentVersion=)(.*)/\1${release_version}/g" ${version_file}
        # use oldVersion as lastVersion
        sed -ri "s/(LastVersion=)(.*)/\1${old_version}/g" ${version_file}
    else
        sed -ri "s/(CurrentVersion=)(.*)/\1${release_version}/g" ${version_file}
    fi
}
#
function rollback_last {
    local job_name="$1"
    version_file=${VERSION_PATH}/${job_name}
    if [[ $# == 1 ]] ;then
        version=$(awk -F "=" 'NR==4&&match($0,'LastVersion') {print $2}' ${version_file})
        if [ "x${version}" != "x" ];then
            # rollback to last version
            ansible-playbook -i ${INVENTORY_PATH}/${JOB_NAME} \
                ${PLAYBOOK_PATH}/${job_name}.yaml -e hosts_group=all -e job_name=${job_name} -e version=${version} --tags "stop,start"
            if [[ "$?" -ne 0 ]]; then
            echo "[Error] Rollback Failed"
            exit 1
            fi
            # set new currentversion
            sed -ri "s/(CurrentVersion=)(.*)/\1${version}/g" ${version_file}
        else
            echo "[Error] Missing Last Version, Please use the specified version to rollback"
            exit 3
        fi
    else
        echo "[Error] Missing JobName"
        exit 1
    fi
}
#
function main {
    local action="$1"
    local job_name="$2"
    local version="$3"
    local host="$4"
    check_version_file ${job_name}
    case "${action}" in
    "build")
    build ${job_name} ${version}
    ;;
    "deploy")
    deploy ${job_name} ${version} ${host}
    ;;
    "rollback-last")
    rollback_last ${job_name}
    ;;
    *)
    echo "[Error] Unknow Action"
    exit 1
    ;;
    esac
}

#main
main $@
