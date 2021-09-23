source /env
eval $(ssh-agent -s)
#export PATH=$PATH:$(go env GOPATH)/bin
#export GOPATH=$(go env GOPATH)

# Custom functions 

function start_vpn(){
    sudo openvpn --config /openvpn.ovpn
}

function stop_vpn(){
    sudo pkill openvpn
}
