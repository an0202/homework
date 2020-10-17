FROM jenkins/jenkins:lts

LABEL maintainer="jie.an"
# install requirement
USER root
RUN apt update && apt install -y curl \
&& curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
&& python get-pip.py --user \
&& python -m pip install ansible \
&& ansible-galaxy collection install community.general

#back to jenkins
USER jenkins
