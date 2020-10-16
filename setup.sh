#!/bin/bash
#
# Function
function init_env {
    # check os
    OS=$(cat /etc/redhat-release)
    if [[ "$?" -eq 0 ]]; then
        echo "[info]System Of Instance Is: ${OS}, prefer RHEL-7/CENTOS-7/AMAZONLINUX-2"
        read -p "Whether to continue installation, Y/N?"  name
        if [ "${name}x" = "Yx" -o "${name}x" = "yx" ]; then
            download_homework
        else
            exit 0
        fi        
    else
        echo "[warning]Unknown system, installation may fail."
        read -p "Whether to continue installation, Y/N?"  name
        if [ "${name}x" = "Yx" -o "${name}x" = "yx" ]; then
           download_homework
        else
            exit 0
        fi        
    fi
}

#download anjie's homework to /data/homework_anjie and setup env
function download_homework {
    # install base tool
    echo "[info] git clone anjie's homework to /data/homework_anjie/"
    yum -y install epel-release && yum -y install git wget python-pip && pip install docker-py
    if [[ "$?" -ne 0 ]]; then
        echo "[error]install base tool failed"
        exit 2
    fi
    echo "[info]get code from github"
    mkdir -p /data/homework_anjie
    cd /data/homework_anjie
    if [[ -d homework ]]; then
        rm -rf homework
        git clone https://github.com/an0202/homework.git
    else
        git clone https://github.com/an0202/homework.git
    fi
    if [[ "$?" -ne 0 ]]; then
        echo "[error]get code from github failed"
        exit 2
    fi
    # env setup
    # check exist of user id=1000 
    echo "[info]setup jenkins user"
    jenkins_user=$(id 1000)
    if [[ "$?" -ne 0 ]]; then
        echo "[warning]User does not exist, create user jenkins with uid 1000"
        useradd -U --uid 1000 jenkins
    fi
    # setup ansible user
    echo "[info]setup ansible user and add to wheel group"
    useradd -G wheel ansible
    # make wheel grup enable
    cat << _EOF > /etc/sudoers.d/sudo_wheel
# Created by thoughtworks devops homework - anjie
%wheel        ALL=(ALL)       NOPASSWD: ALL

_EOF
    chmod 440 /etc/sudoers.d/sudo_wheel
}

# download content
function download_content {
    echo "[info]download necessary content to /data/homework_anjie/ , it may take several minutes"   
    # get content from file webserver
    echo "[info]get content from file webserver"
    mkdir -p /data/homework_anjie
    cd /data/homework_anjie
    wget http://18.163.240.152:8123/jenkins.tar.gz .
    if [[ "$?" -ne 0 ]]; then
        echo "[error]get content from file webserver failed"
        exit 2
    fi       
}

# check docker
function check_docker {
        docker_cmd=$(which docker)
        if [ -z "${docker_cmd}" ]; then
                echo "[info]The docker has not been installed."
                echo "[info]Start to install docker."
                install_docker
        else
                echo "[info]The current docker version: `${docker_cmd} -v` ."
                read -p "Whether reinstall docker, Y/N?"  name
                if [ "${name}x" = "Yx" -o "${name}x" = "yx" ]; then
                        yum -y remove docker-io
                        install_docker
                else
                        exit 0
                fi
        fi
}

# install docker ce, prefer centos/rhel 7
function install_docker {
    echo "[info]install docker-ce, prefer RHEL-7/CENTOS-7/AMAZONLINUX-2"
    # Install docker-ce
    yum install -y yum-utils   device-mapper-persistent-data   lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    # Data Node
    mkdir -p /data/dockerdata
    sed -i s@^ExecStart=.*@"ExecStart=/usr/bin/dockerd --graph /data/dockerdata -H unix://"@ /usr/lib/systemd/system/docker.service
    systemctl enable docker
    systemctl start docker
}


# run jenkins container
function install_jenkins {
    install j
}

#
function main {
    local action="$1"
    case "${action}" in
    "init")
    init_env
    ;;
    *)
    echo "[Error] Unknow Action"
    exit 1
    ;;
    esac
}

#main
main $@
