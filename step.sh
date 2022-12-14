#!/bin/bash
set -eu

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo "Preparing CA"
    echo "${ca_crt}" > /etc/openvpn/ca.crt
    echo "Preparing TA"
    echo "${ta_key}" > /etc/openvpn/ta.key
    echo ${user} > /etc/openvpn/auth.txt
    echo ${password} >> /etc/openvpn/auth.txt

    cat <<EOF > /etc/openvpn/client.conf
client
dev tun
remote ${host} ${port} ${proto}
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
ca /etc/openvpn/ca.crt
tls-auth /etc/openvpn/ta.key
auth-user-pass /etc/openvpn/auth.txt
cipher AES-256-CBC
auth SHA256
tls-client
remote-cert-tls server
setenv CLIENT_CERT 0
key-direction 1
EOF
    service openvpn start client > /dev/null 2>&1
    sleep 5

    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    echo "Configuring for Mac OS"
    
    echo "${ca_crt}" > ca.crt
    echo "${ta_key}" > ta.key
    echo ${user} > auth.txt
    echo ${password} >> auth.txt

    # We call openvpn as a command, indicating all the necessary parameters by command line
    sudo openvpn --client --tls-client --remote-cert-tls server --resolv-retry infinite --dev tun --proto ${proto} --remote ${host} ${port} --auth-user-pass auth.txt --auth SHA256 --persist-key --persist-tun --compress lz4-v2 --cipher AES-256-CBC --ca ca.crt --tls-auth ta.key --key-direction 1 > /dev/null 2>&1 &
    
    sleep 5

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
