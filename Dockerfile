FROM ghcr.io/linuxserver/code-server:version-v3.10.1


ENV go_version 1.16.3
ENV kind_version 0.10.0
ENV helm_version 3.5.4
ENV docker_id 998

# clusterctl tool (set to "" to not install, uses git tag/ref/branch/sha)
ENV clusterctl_version "v0.4.3"
# Openstack cli tools (set to "" to not install)
ENV openstack_cli "true"

# set as "" to not install
# OR set to git sha/branch/tag

ENV devctl_version=master
ENV opsctl_version=master

ENV gsctl_version=master
# gsctl_url/gsctl_release is used instead of gsctl_version.
#   We cannot run make for gsctl during a docker build because the make uses a docker run command internally
ENV gsctl_release 1.1.0
ENV gsctl_url https://github.com/giantswarm/gsctl/releases/download/${gsctl_release}/gsctl-${gsctl_release}-linux-amd64.tar.gz

ENV GOPATH /usr/local/go
ENV GOBIN $GOPATH/bin

RUN apt update && \
    apt install curl \
                git \
		wget \
		ca-certificates \
		openvpn \
                -y 

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

## Install docker cli

RUN groupadd -g ${docker_id} docker && \
    usermod -aG docker abc

RUN apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    -y

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    apt-get install docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    -y

## Install latest golang

RUN wget -c https://golang.org/dl/go${go_version}.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local/
ENV PATH $PATH:/usr/local/go/bin 

## Install kubectl

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

## Install helm

ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${helm_version}-linux-amd64.tar.gz"

RUN curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm 

# Install kind

RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${kind_version}/kind-linux-amd64 && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/kind

## GiantSwarm tools
RUN apt update && \
    apt install -y build-essential

RUN mkdir /giantswarm
RUN --mount=type=ssh ssh-keyscan -t rsa github.com >> /tmp/known_hosts 

## opsctl

RUN --mount=type=ssh if [ "$opsctl_version" != "" ] ; then \
    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/tmp/known_hosts" \
    git clone git@github.com:giantswarm/opsctl.git /giantswarm/opsctl && \
    cd /giantswarm/opsctl && \
    git checkout ${opsctl_version} && \
    make && make install; \
    fi

# gsctl

#TODO get gsctl build to work
#RUN --mount=type=ssh if [ "$gsctl_version" != "" ] ; then \
#    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/tmp/known_hosts" \
#    git clone git@github.com:giantswarm/gsctl.git /giantswarm/gsctl && \
#    cd /giantswarm/gsctl && \
#    git checkout ${gsctl_version} && \
#    make && make install;\
#    fi
WORKDIR /giantswarm
RUN wget $gsctl_url -O ./gsctl.tar.gz  && \
    tar -xf ./gsctl.tar.gz && \
    chmod +x ./gsctl-${gsctl_release}-linux-amd64 && \
    mv ./gsctl-${gsctl_release}-linux-amd64/gsctl $GOBIN/

## devctl

RUN --mount=type=ssh if [ "$devctl_version" != "" ] ; then \
    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/tmp/known_hosts" \
    git clone git@github.com:giantswarm/devctl.git /giantswarm/devctl && \
    cd /giantswarm/devctl && \
    git checkout ${devctl_version} && \
    make && make install; \
    fi

## openvpn

RUN apt-get -y install debconf-utils && \
    echo resolvconf resolvconf/linkify-resolvconf boolean false | debconf-set-selections && \
    apt-get -y install resolvconf

RUN apt install -y \
    openvpn \
    resolvconf \
    ifupdown \
    dialog \
    apt-utils

# Openstack-cli

RUN if [ "$openstack_cli" != "" ] ; then \
    apt install -y python-dev python-pip && \
    pip install python-openstackclient; \
    fi

# clusterctl_version

# Use prebuilt release
# RUN if [ "$clusterapi_version" != "" ] ; then \
#     curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/${clusterapi_version}/clusterctl-linux-amd64 -o /ginatswarm/clusterctl && \
#     chmod +x /giantswarm/clusterctl && \    
#     sudo mv /giantswarm/clusterctl /usr/local/bin/clusterctl ; \
#     fi

RUN --mount=type=ssh if [ "$clusterctl_version" != "" ] ; then \
    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/tmp/known_hosts" \
    git clone git@github.com:kubernetes-sigs/cluster-api.git /giantswarm/clusterctl && \
    cd /giantswarm/clusterctl && \
    git checkout ${clusterctl_version} && \
    make all && cp ./bin/clusterctl /usr/local/bin/clusterctl ; \
    fi

##########

WORKDIR /
