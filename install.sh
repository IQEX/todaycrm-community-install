#/bin/bash

# --------------------------------------------------------------------------
# Как установить:
# curl 
# --------------------------------------------------------------------------

echo "Install MongoDB"

sudo apt update
sudo apt -y install mongodb
sudo systemctl status mongodb
sudo systemctl enable mongodb
sudo systemctl start mongodb

# настройка конфига

HOST_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
[ -z ${HOST_IP} ] && read -p "Enter local address (IP): " HOST_IP
echo "Localhost IP is $HOST_IP"
sudo sed -i "s/bind_ip = 127.0.0.1\n/bind_ip = 127.0.0.1,$HOST_IP\n/g" /etc/mongodb.conf
echo "Config file /etc/mongodb.conf patched!"

# открытие пора наружу (если нужен будет доступ в базу снаружи)
# sudo ufw allow from trusted_server_ip/32 to any port 27017
# sudo ufw status

echo "Restarting MongoDB..."
sudo systemctl restart mongodb && sleep 2
sudo systemctl status mongodb
mongo --eval 'db.runCommand({ connectionStatus: 1 })'  
echo "MongoDB installed!"

# установка NodeJS

#cd ~
#curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
#sudo bash nodesource_setup.sh
#sudo apt install nodejs
#nodejs -v

# Установить NVM?

#??? https://tecadmin.net/how-to-install-nvm-on-ubuntu-20-04/

# установка Node Package Manager (NPM)

echo "Install NodeJS & NPM..."
sudo apt update
sudo apt -y install nodejs npm
echo "NodeJS & NPM installed!"

# установка менеджера PM2

sudo npm install pm2@latest -g
pm2 startup systemd
pm2 list
# todo remove all out of pm2 (на всякий случай)

# установка сервера 

sudo apt upgrade
sudo apt-get install -y lighttpd

# установка bcrypt

sudo apt-get install -y node-gyp

# подготовка директорий

[ -d /opt/skillforce ] || mkdir /opt/skillforce
[ -d /opt/skillforce-update ] || mkdir /opt/skillforce-update
[ -d /opt/skillforce-backup ] || mkdir /opt/skillforce-backup