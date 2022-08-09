#/bin/bash

# --------------------------------------------------------------------------
# Installation for Yandex Cloud
# --------------------------------------------------------------------------

# Installation options
OPT_INSTALL_MONGODB=true
OPT_INSTALL_NODEJS=true
OPT_INSTALL_PM2=true
OPT_INSTALL_HTTPD=true
OPT_INSTALL_NVM=true
OPT_USE_MONGODB_OUTSIDE=false # use mongodb outside of the server (tune firewall)
OPT_USE_VPN=true
OPT_VPN_PUBLIC_IP=157.230.108.201 # public IP for vpn tunnel if used

# Install common packages

sudo bash -c "apt update -y"
sudo apt install net-tools
sudo apt install curl

# Set environment variables
IFACE=eth0
IF_IP=$(/sbin/ip -o -4 addr list $IFACE | awk '{print $4}' | cut -d/ -f1)
IF_MASK=$(ifconfig | grep -A 7 "$IFACE" | sed -nr 's/^.*netmask\s([0-9\.]+)\s\sbroadcast.*$/\1/p')
IF_GW=$(echo $IF_IP | sed -nr 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\.([0-9]{1,3})/\1.1/p')
IF_SUBNET=$(echo $IF_IP | sed -nr 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\.([0-9]{1,3})/\1.0/p')

# Print environment variables
echo "--------------------------------------------------------------------------"
echo "ENVIRONMENT"
echo "Network interface ${IFACE}"
echo "Host IP address is ${IF_IP}"
echo "Host IP mask is ${IF_MASK}"
echo "Host IP gateway is ${IF_GW}"
echo "Host IP subnet is ${IF_SUBNET}"
echo "--------------------------------------------------------------------------"

echo "Checking environment..."

if ! [[ $(lsb_release -rs) == "20.04" ]]; then 
    echo "Non-compatible Ubuntu version, please use Ubuntu 20.04 LTS... FAILED"
    exit 1
else    
    echo "Ubuntu 20.04 LTS... OK"
fi

if ! [[ $(ps -ef | grep mongod | grep -v grep | wc -l | tr -d ' ') == "0" ]]; then
    OPT_INSTALL_MONGODB=false
    echo "MongoDB already installed... OK"
fi

if ! [[ $IF_MASK == "255.255.255.0" ]]; then
    echo "Incompatable host mask, should be 255.255.255.0... FAILED"
    exit 1
else
    echo "Host IP Mask... OK"
fi

echo "--------------------------------------------------------------------------"
echo "INSTALLATION OPTIONS"
echo "- use VPN is ${OPT_USE_VPN}"
echo "- install MongoDB is ${OPT_INSTALL_MONGODB}"
echo "- use MongoDB outside is ${OPT_USE_MONGODB_OUTSIDE}"
echo "- install NodeJS is ${OPT_INSTALL_NODEJS}"
echo "- install PM2 Manager is ${OPT_INSTALL_PM2}"
echo "- install HTTPD is ${OPT_INSTALL_HTTPD}"
echo "- install NVM is ${OPT_INSTALL_NVM}"
echo "--------------------------------------------------------------------------"


# Switch on VPN
# ----------------------------------------------------------------------------------

if $OPT_USE_VPN ; then

    # sudo apt update
    sudo apt install openvpn -y

    if [[ $(cat /etc/iproute2/rt_tables | grep "vpnbypass" | wc -l) == "0" ]]; then

        echo "VPN: adding vpnbypass route table..."

        # Add route table

        sudo cp /etc/iproute2/rt_tables /tmp/rt_tables
        sudo chmod 777 /tmp/rt_tables
        echo "250   vpnbypass" >> /tmp/rt_tables
        sudo chmod 644 /tmp/rt_tables
        sudo mv /tmp/rt_tables /etc/iproute2/rt_tables

        # Check route table!

        if [[ $(cat /etc/iproute2/rt_tables | grep "vpnbypass" | wc -l) == "1" ]]; then
            echo "VPN: route table has been added... OK"
        else
            echo "VPN: Can't add route table... FAILED" && exit 1
        fi

        # Add routes to VPN BYPASS table

        echo "sudo ip rule add from $IF_SUBNET/20 table vpnbypass"
        echo "sudo ip rule add to $IF_SUBNET/20 table vpnbypass"
        echo "sudo ip rule add to 169.254.169.254 table vpnbypass"
        echo "sudo ip route add table vpnbypass to $IF_SUBNET/20 dev $IFACE"
        echo "sudo ip route add table vpnbypass default via $IF_GW dev $IFACE"

        sudo ip rule add from $IF_SUBNET/20 table vpnbypass
        sudo ip rule add to $IF_SUBNET/20 table vpnbypass
        sudo ip rule add to 169.254.169.254 table vpnbypass
        sudo ip route add table vpnbypass to $IF_SUBNET/20 dev $IFACE
        sudo ip route add table vpnbypass default via $IF_GW dev $IFACE

        echo "VPN: routes added or updated... OK"     
    
    else
    
        echo "VPN: route table vpnbypass already presented... OK"

    fi

    # Run VPN tunnel daemon

    if [ -e ./vpn/client.ovpn ]; then

        sudo openvpn --config vpn/client.ovpn --daemon && sleep 10
        echo "VPN: OpenVPN client daemon started... OK"

        VPN_PUBLIC_IP=$(curl ifconfig.me)
        echo "VPN: Public IP VPN tunnel is $VPN_PUBLIC_IP"
        echo "VPN: Public IP VPN tunnel should be $OPT_VPN_PUBLIC_IP"

        if [[ $VPN_PUBLIC_IP == $OPT_VPN_PUBLIC_IP ]]; then
            echo "VPN: Pulbic IP is correct... OK"
        else
            echo "VPN: Pulbic IP is incorrect... FAILED" && exit 1
        fi

        # Update packages under VPN

        sudo bash -c "apt update -y"

    else

        echo "VPN: OpenVPN client profile file not found (./vpn/client.ovpn)... FAILED" && exit 1

    fi

    # OK

    echo "VPN: Tunnel is ready... OK"

fi

# Install MongoDB
# ----------------------------------------------------------------------------------

if $OPT_INSTALL_MONGODB ; then

    echo "MongoDB 4.4 installation..."

    # Официальная документация по установке MongoDB 4.4 на Ubuntu 20.4 приведена 
    # https://www.mongodb.com/docs/v4.4/tutorial/install-mongodb-on-ubuntu/?_ga=2.156300795.1195631599.1658911956-375212060.1658911955"

    if ! [ -f /usr/bin/mongod ]; then

        # Get official mongodb 4.4 and install it
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        sudo bash -c 'echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list'
        sudo apt-get update
        sudo apt-get install -y mongodb-org=4.4.15 mongodb-org-server=4.4.15 mongodb-org-shell=4.4.15 mongodb-org-mongos=4.4.15 mongodb-org-tools=4.4.15

        sudo systemctl daemon-reload
        sudo systemctl start mongod
        sudo systemctl enable mongod

        echo "MONGO: MongoDB installed... OK"

        if $OPT_USE_MONGODB_OUTSIDE ; then

            echo "MONGO: MongoDB patching..."

            sudo sed -i "s/bind_ip = 127.0.0.1\n/bind_ip = 127.0.0.1,$IF_IP\n/g" /etc/mongodb.conf
            echo "MONGO: MongoDB config file /etc/mongodb.conf patched... OK"

            # tune firewall to allow export port
            sudo ufw allow from trusted_server_ip/32 to any port 27017
            sudo ufw status
            sudo systemctl restart mongod

        fi

    else

        echo "MONGO: MongoDB is already installed... OK"

    fi

fi

# Check MongoDB connection...
# ----------------------------------------------------------------------------------

echo "MONGO: Check connection..."
mongo --version | head -n 1 && sleep 5

if [[ $(mongo --eval 'db.runCommand({ connectionStatus: 1 })' | grep '"ok" : 1' | wc -l) == "1" ]]; then
    echo "MONGO: Connection presented... OK"
else
    sudo systemctl status mongod
    mongo --eval 'db.runCommand({ connectionStatus: 1 })'
    echo "MONGO: Connection refused... FAILED"  && exit 1
fi

# Install NodeJS
# ----------------------------------------------------------------------------------

if $OPT_INSTALL_NODEJS ; then

    echo "NodeJS 16.x installation..."

    curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
    sudo bash nodesource_setup.sh
    sudo apt install nodejs

    if [[ $(node -v) == "v16.16.0" ]] ; then
        echo "NodeJS 16.16.0 installed... OK"
    else
        node -v
        echo "NodeJS is not installed... FAILED" && exit 1
    fi

    # NPM goes together with NodeJS, check also for target version

    if [[ $(npm -v) == "8.11.0" ]] ; then
        echo "Node Package Manager (NPM) 8.11.0 installed... OK"
    else
        npm -v
        echo "Node Package Manager (NPM) 8.11.0 isn't installed... FAILED" && exit 1
    fi
fi

# Install NVM
# ----------------------------------------------------------------------------------

if $OPT_INSTALL_NVM ; then

    echo "Node Version Manager (NVM) installation..."

    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

    # load NVM

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Check NVM version (пока проверить не получается, так как требуется перелогин после установки NVM)

    if [[ $(nvm -v) == "0.39.1" ]] ; then
        echo "Node Version Manager (NVM) v.0.39.1 installed... OK"
    else
        nvm -v
        echo "Node Version Manager (NVM) v.0.39.1  isn't installed... FAILED" && exit 1
    fi    

fi

# Install PM2
# ----------------------------------------------------------------------------------

if $OPT_INSTALL_PM2 ; then

    sudo npm install pm2@latest --location=global
    pm2 startup systemd
    # pm2 delete all
fi

if [[ $(pm2 ping | grep 'pong' | wc -l) == "1" ]]; then
    echo "PM2: Installed and working... OK"
else
    pm2 ping
    echo "PM2: Not installed correctly... FAILED"  && exit 1
fi

# Install HTTPD
# ----------------------------------------------------------------------------------

if $OPT_INSTALL_HTTPD ; then

    sudo apt-get install -y lighttpd

    if [[ $(lighttpd -v) == "lighttpd/1.4.55 (ssl) - a light and fast webserver" ]] ; then
        echo "Lighttpd 1.4.15 installed... OK"
    else
        lighttpd -v
        echo "Lighttpd 1.4.15 isn't installed... FAILED" && exit 1
    fi   

fi

# Create directories

[ -d /opt/skillforce ] || sudo mkdir /opt/skillforce
[ -d /opt/skillforce-update ] || sudo mkdir /opt/skillforce-update
[ -d /opt/skillforce-backup ] || sudo mkdir /opt/skillforce-backup
[ -d /var/lib/sf-uploads ] || sudo mkdir /var/lib/sf-uploads

# Set permisions (allow remote update /var/www)

sudo chown -R admin:admin /var/www
sudo chown -R admin:admin /opt/skillforce
sudo chown -R admin:admin /opt/skillforce-update
sudo chown -R admin:admin /opt/skillforce-backup
sudo chown -R admin:admin /var/lib/sf-uploads

# Close VPN tunnel

if $OPT_USE_VPN ; then
    sudo killall openvpn
    echo "VPN: Close VPN tunnel... OK"
fi

echo "DONE"

# echo "Run PM2 Dashboard"
# pm2 dash