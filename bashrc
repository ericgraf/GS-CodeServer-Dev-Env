source /env
eval $(ssh-agent -s)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/usr/local/go/bin:/giantswarm/go/bin:/usr/local/go/bin:/giantswarm/go/bin


# Custom functions 

function start_vpn(){
    sudo openvpn --config /openvpn.ovpn
}

function stop_vpn(){
    sudo pkill openvpn
}
