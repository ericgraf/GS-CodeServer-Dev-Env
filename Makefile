
# Mounts
openvpn_config := `pwd`/vpnconfig.ovpn
env_vars := `pwd`/env_vars
code_repo := `pwd`/config
ssh_repo := $(shell readlink -f ~/.ssh/)
bashrc := $(shell readlink -f `pwd`/bashrc)

container_name=code-server-environment

GUID := $(shell id -G | awk -F ' ' '{print $$1}')
UID := $(shell id -u)
web_port := 8082


hash_password:
	$(eval salt := $(shell tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ))
	$(eval WEB_PASSWORD := $(shell read -p "Web password: " pwd; echo $$pwd))
	$(eval web_hashed_password := $(shell echo $(WEB_PASSWORD) | openssl passwd -6 -salt $(salt) -stdin))
	$(eval SUDO_PASSWORD ?= $(shell read -p "Sudo password: " pwd; echo $$pwd))
	$(eval sudo_hashed_password := $(shell echo $(SUDO_PASSWORD) | openssl passwd -6 -stdin))

start: stop build run

	echo "\n\n\n\nPlease open:\n\n\t http://localhost:$(web_port)/?folder=/config/ \n\n"

build:
	$(eval docker_id=$(shell getent group docker | awk -F ':' '{ print $$3}'))
	echo "Docker group id: $docker_id"

	docker rm -f ${container_name}-image

	DOCKER_BUILDKIT=1 docker build \
		--build-arg docker_id=${docker_id} \
		--ssh default \
		-t ${container_name}-image \
		--progress=plain \
		. 

run: hash_password stop
	
	docker run -d \
	--name=${container_name} \
	-e PUID=${UID} \
	-e PGID=${GUID} \
	-e TZ=America/Toronto \
	-e PASSWORD="${WEB_PASSWORD}"  \
	-e SUDO_PASSWORD="${SUDO_PASSWORD}" \
	-e PROXY_DOMAIN=localhost \
	--net=bridge \
	-p $(web_port):8443 \
	-v `pwd`/config:/config \
	-v ${env_vars}:/env \
	-v ${ssh_repo}:/config/.ssh \
	-v ${bashrc}:/config/.bashrc \
	-v ${openvpn_config}:/openvpn.ovpn \
	-v /var/run/docker.sock:/var/run/docker.sock \
	--restart unless-stopped \
	--privileged \
	${container_name}-image:latest

    
    # TODO get hash password working

	# docker run -d \
	# --name=${container_name} \
	# -e PUID=${UID} \
	# -e PGID=${GUID} \
	# -e TZ=America/Toronto \
	# -e HASHED_PASSWORD="${web_hashed_password}"  \
	# -e SUDO_PASSWORD_HASH="$$6$$$(salt)$$${sudo_hashed_password}" \
	# -e PROXY_DOMAIN=localhost \
	# --net=bridge \
	# -p $(web_port):8443 \
	# -v `pwd`/config:/config \
	# -v ${env_vars}:/env \
	# -v ${ssh_repo}:/config/.ssh \
	# -v ${bashrc}:/config/.bashrc \
	# -v ${openvpn_config}:/openvpn.ovpn \
	# -v /var/run/docker.sock:/var/run/docker.sock \
	# --restart unless-stopped \
	# --privileged \
	# ${container_name}-image:latest


stop: 
	docker rm -f ${container_name}

clean: stop 