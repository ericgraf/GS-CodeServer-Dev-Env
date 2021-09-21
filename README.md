This project is to setup a Giantswarm development environment that uses code-server as the main interface into the environment. Code-server runs on the remote machine and has a webui with a terminal. This allows you easily setup a work server and access your environment from any dumb terminal.


# bash function added
Some bash functions have been added to make life easier

- `start_vpn` starts vpn expecting `/openvpn.ovpn` to exist
- `stop_vpn` stop vpn


# Requirements

- ssh-agent with github key loaded ie `eval $(ssh-agent -s)` `ssh-add ~/.ssh/<githubkey>` verifu with `ssh-add -l`
- env_vars in local folder with proper values
- (optional) vpnconfig.ovpn in local folder 
- 

# Initial setup config

## Code Server Port

Found in Makefile defaults to `8082` right now.

## Environment variables ( required )

```bash
cp env_vars.template env_vars

#Change values as see fit
vi env_vars
```

## Docker mounts / Tool versions

### Docker mounts

`vi Makefile`

* `openvpn_config` this is the path to your personal openvpn config file eg `username.ovpn`
* `env_vars` path to environment variables file that gets run in `bashrc` when new terminal is launched in webui
* `code_repo` path to code-server repo where all data and workspaces is stored
* `ssh_repo` path to ssh keys that is mounted in container 
* `bashrc` path to bashrc file

## Tool versions

`vi Dockerfile`

* `go_version`
* `kind_version` 
* `helm_version`
* `docker_id` docker group id required to run docker commands with sudo

### Giantswarm tools

All GS tools and code repos are stored in /gianswarm repo in container. The GOPATH is set to /giantswarm/go where the binaries will be installed.

* `devctl_version` git tag/sha/branch to use
* `opsctl_version` git tag/sha/branch to use
* `gsctl_version` This is currently ignored. 
* `gsctl_release` / `gsctl_url` url to gsctl release tar. This is pulled and installed into `/giantswarm/go/bin` 



# Standing up development environment

`make start`

## Teardown Environment

`make stop`

*note* some kind resource may be still present please verify they are cleaned up. 

Helpfull commands

`docker ps`

`docker system prune --all`
