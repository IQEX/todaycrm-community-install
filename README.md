Здесь описывается то, как поставить TODAYCRM на свой сервер.

# Структура директории

* vpn - конфиг для оргнанизации VPN канала с помощь OpenVPN

# VPN-туннель

VPN-туннель необходим для установки пакетов, которые недоступны из РФ. Это позволяет обойти ограничения провайдеров и скачать нужные компоненты без ограничений.

## Как обновить ключи VPN

1. установить в Digital Ocean сервер Ubuntu с OpenVPN Server (Free, данная версия разрешает 2 соединения)
2. добавить учетную запись через интерфейс администратора
3. зайти в веб-интерфейс OpenVPN Server с кредами созданного пользователя (при входе даст возможность выгрузить ovpn файлы)
4. скачать ovpn с профилем autologon с в папку VPN под именем файла client.ovpn (данный профиль не будет просить пароль, а сразу даст возможность подключиться)

### Как настроить VPN BYPASS

При подключении к серверу Ubuntu и настройке туннеля VPN будет теряться сессия SSH. Чтобы этого не происходило надо настроить таблицы маршрутизации таким образом, что трафик внутри сети, где установлен сервре Ubuntu, шел минуя VPN. Для этого надо выполнить следующие действия.

```
sudo apt install net-tools
ifconfig # получить IP адрес интрефейса eth0 %IP% (например 10.129.0.4) и %MASK% (например 10.129.0.0)
ip route show # получить Gateway %GATEWAY% (например 10.129.0.1)
sudo su # для добавления таблицы vpnbypass
echo "250   vpnbypass" >> /etc/iproute2/rt_tables
exit # выход из sudo
sudo ip rule add from %MASK%/20 table vpnbypass
sudo ip rule add to %MASK%/20 table vpnbypass
sudo ip rule add to 169.254.169.254 table vpnbypass
sudo ip route add table vpnbypass to %MASK%/20 dev eth0
sudo ip route add table vpnbypass default via %GATEWAY% dev eth0
```

После этой настройки должен сохранить канал SSH.

### Как проверить VPN

```
sudo apt update
sudo apt install openvpn -y
sudo openvpn --config client.ovpn # должен дойти до сообщение, что все корректно инициализровано (прервывать выполнение, поскольку оно запущено на foreground)
sudo openvpn --config client.ovpn --daemon # запустить как демон кала (проверить в интерфейсе OpenVPN сервера наличие соединения)
ip a show tun0 # должен быть интерфейс tun0
curl ifconfig.me # должен вернуться вншений публичный адрес уже из канала VPN
```

### Как запустить VPN туннель

Если VPN туннель настроен корректно, то запускается он как демон следующей командой

```
sudo openvpn --config client.ovpn --daemon
```

Проверить успешность запуска также можно просто проверив, какой внешний IP теперь виден.

```
curl ifconfig.me
```

### Как отключить VPN туннель

```
sudo killall openvpn
```

# Пререквизиты

1. Ubuntu 20.04 (LTS)

# Установка

## Что будет установлено

1. MongoDB 4.4.15 с официального сервера

## Порядок установки

```
cd ~ 
curl https://raw.githubusercontent.com/IQEX/todaycrm-community-install/main/install.sh --output ~/install.sh
sudo chmod 755 ~/install.sh
./install.sh
```

# TODO

https://api.github.com/repos/IQEX/todaycrm-community-install/releases | grep browser_download_url | grep '64[.]deb' | head -n 1 | cut -d '"' -f 4

Read this: 

https://docs.github.com/en/rest/releases/releases#get-the-latest-release

# Установка MongoDB

Официальная документация по установке MongoDB 4.4 на Ubuntu 20.4 приведена тут.
https://www.mongodb.com/docs/v4.4/tutorial/install-mongodb-on-ubuntu/?_ga=2.156300795.1195631599.1658911956-375212060.1658911955

```
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.listlist.d/mongodb-org-4.4.list
sudo apt-get update # у меня она заканчивается но с ошибками NOSPLIT (проигнорировать)
sudo apt-get install -y mongodb-org=4.4.15 mongodb-org-server=4.4.15 mongodb-org-shell=4.4.15 mongodb-org-mongos=4.4.15 mongodb-org-tools=4.4.15
```

## Прописать MongoDB как сервис

По умолчанию, сервис MongoDB уже будет зарегистрирован в системе как mongod. Для его включения достаточно дать команду

```
sudo systemctl start mongod
```

Однако, если он будет все же не найде, то попробовать сначала перезапустить службу демонов и снова запустить mongod

```
sudo systemctl daemon-reload
sudo systemctl start mongod
```

Проверить, что MongoDB поднялась

```
netstat -plntu | grep ":27017" # порт 27017 должен быть задействован службой Mongo
```

Настроить службу на автоматическое включение при запуске системы

```
sudo systemctl enable mongod
```


### Альтернативный(!) способ зарегистрировать свою службу MongoDB

Если по какой-то причине необходимо зарегистрировать службу MongoDB как отдельную службу, то можно выполнить выполнить следующие команды.

```
sudo cp ./mongodb/mongodb.service /etc/systemd/system/mongodb.service # ./mongodb/mongodb.service береться из пакета этого дистрибутива
sudo systemctl daemon-reload
sudo systemctl start mongodb
```


# Удаление

## Удаление MongoDB

Для удаление пакетов официальной MongoDB используйте команду

```
sudo apt-get purge mongodb-org*
```

Для удаление пакетов неофициальной MongoDB, установленной с зеркала Yandex

```
sudo apt-get purge mongodb*
```


# Если понадобится NVM

https://tecadmin.net/how-to-install-nvm-on-ubuntu-20-04/