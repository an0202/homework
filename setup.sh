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
    local work_path="/data/homework_anjie"
    # install base tool
    echo "[info] Clone anjie's homework to /data/homework_anjie/"
    yum -y install epel-release && yum -y install git wget python-pip && pip install docker-py
    if [[ "$?" -ne 0 ]]; then
        echo "[error]Install base tool failed"
        exit 2
    fi
    echo "[info]Get code from github"
    mkdir -p ${work_path}
    cd ${work_path}
    if [[ -d ${work_path}/homework ]]; then
        rm -rf ${work_path}/homework
        git clone https://github.com/an0202/homework.git
    else
        git clone https://github.com/an0202/homework.git
    fi
    if [[ "$?" -ne 0 ]]; then
        echo "[error]Get code from github failed"
        exit 2
    fi
    # env setup
    # check exist of user id=1000
    echo "[info]Setup jenkins user"
    jenkins_user=$(id 1000)
    if [[ "$?" -ne 0 ]]; then
        echo "[warning]User does not exist, create user jenkins with uid 1000"
        useradd -U --uid 1000 jenkins
    fi
    # setup ansible user
    echo "[info]Setup ansible user and add to wheel group and public key for jenkins access"
    useradd -G wheel ansible
    if [[ -d /home/ansible/.ssh ]]; then
        cat ${work_path}/homework/jenkins/.ssh/authorized_keys >> /home/ansible/.ssh/authorized_keys
        chmod 600 /home/ansible/.ssh/authorized_keys
        chown ansible:ansible /home/ansible/.ssh/authorized_keys
    else
        cp -r ${work_path}/homework/jenkins/.ssh/ /home/ansible/
        chmod 700 /home/ansible/.ssh/
        chmod 600 /home/ansible/.ssh/authorized_keys
        chown -R ansible:ansible /home/ansible/.ssh/
    fi
    # make wheel grup enable
    cat << _EOF > /etc/sudoers.d/sudo_wheel
# Created by thoughtworks devops homework - anjie
%wheel        ALL=(ALL)       NOPASSWD: ALL

_EOF
    chmod 440 /etc/sudoers.d/sudo_wheel
}

# download content for jenkins
function download_content {
    echo "[info]Download necessary content for jenkins to /data/homework_anjie/ , it may take several minutes"
    # get content from file webserver
    echo "[info]Get content from file webserver"
    if [[ -d /data/homework_anjie ]]; then
        rm -f /data/homework_anjie/jenkins.tar.*
        wget -P /data/homework_anjie "http://shellan.top:8123/jenkins.tar.gz"
        if [[ "$?" -ne 0 ]]; then
            echo "[error]Get content from file webserver failed"
            exit 2
        fi
    else
        download_homework
        wget -P /data/homework_anjie "http://shellan.top:8123/jenkins.tar.gz"
        if [[ "$?" -ne 0 ]]; then
            echo "[error]Get content from file webserver failed"
            exit 2
        fi
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
    echo "[info]Install docker-ce, prefer RHEL-7/CENTOS-7/AMAZONLINUX-2"
    # Install docker-ce
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    systemctl enable docker
    systemctl start docker
    echo "[info]Docker CE installed"
}

# run jenkins container
function install_jenkins {
    download_content
    #setup jenkins home
    echo "[info]Init jenkins_home, import config"
    local work_path="/data/homework_anjie"
    tar zxvf ${work_path}/jenkins.tar.gz -C ${work_path}/
    chown -R 1000:1000 ${work_path}/jenkins_home
    # build jenkins image
    echo "[info]Build jenkins with docker file"
    docker build -t homework/anjie:jenkins -f ${work_path}/homework/jenkins/Dockerfile ${work_path}/homework/jenkins/
    if [[ "$?" -ne 0 ]]; then
        echo "[error]Build jenkins image failed"
        exit 2
    fi
    # start jenkins
    docker run -d --name jenkins-anjie -p 8080:8080 -p 50000:50000 -v ${work_path}/jenkins_home:/var/jenkins_home homework/anjie:jenkins
    if [[ "$?" -ne 0 ]]; then
        echo "[error]Start jenkins failed"
        exit 2
    fi
    #
    echo "[info]Jenkins setup successfully, access it by http://your-host-ip:8080, username/password: thoughtworks"
}

# Usage
function usage {
    echo "### Require CENTOS7/RHEL7/AMAZON LINUX2"
    echo "### Please run this scripts by root user"
    echo "### Online Demo: http://shellan.top:8080 username/password: thoughtworks"
    echo "### For more details see : https://github.com/an0202/homework"
    echo "$0 init    -- 'download homework to /data/anjie_homework/ and setup local env, we need this setup first'"
    echo "$0 docker  -- 'install docker-ce on local instance'"
    echo "$0 jenkins -- 'setup jenkins container on local docker engine'"
    echo "$0 all     -- 'setup all on local instance'"
}

#
function main {
    local action="$1"
    case "${action}" in
    "init")
    init_env
    ;;
    "docker")
    check_docker
    ;;
    "jenkins")
    install_jenkins
    ;;
    "all")
    usage
    init_env
    check_docker
    install_jenkins
    ;;
    usage
    exit 0
    ;;
    esac
}

#main
main $@
