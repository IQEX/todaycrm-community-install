Здесь описывается то, как поставить TODAYCRM на свой сервер в Yandex.Cloud.

# Структура

 ┗ docs
 ┃ ┗ VPN.md - документация, как сделать VPN туннель
 ┗ releases
   ┃ ┗ latest
   ┃ ┃ ┗ download
   ┃ ┃ ┃ ┗ package.zip - основной пакет самой последней версии системы для постоянной
 ┗ vpn
 ┃ ┗ client.ovpn - конфиг профиля для оргнанизации VPN канала с помощь OpenVPN Client (не включен в поставку)
 ┗ install.sh - основной скрипт для развертывания приложения на сервере

# Требования к окружению

Для успешной установки вам потребуется иметь на своем компьютере

1. Windows 
2. ssh клиент для удаленного доступа на сервер
3. git клиент с правами на репозиторий https://github.com/IQEX/todaycrm-community.git
4. docker desktop
   
## Порядок установки

1. Создайте виртуальную машину в Yandex Cloud со следующими характеристиками

- ОС Ubuntu 20.04 (LTS) (чистая)
- 15Gb SSD
- 1 VPU (50%)
- в качестве прав доступа укажите имя admin и закрытый ключ, который находится в папке ./deploy/.ssh_key/id_rsa.pub репозитория https://github.com/IQEX/todaycrm-community.git

2. Подключитесь в ОС Ubuntu по SSH с использованием ключа ./deploy/.ssh_key/id_rsa

2. Подготовьте окружение ОС Ubuntu, выполнив следующие команды

Внимание: прочитайте полностью параграф до выполнения команд.

```
cd ~ 
mkdir ./vpn
curl <your_vpn_ovpn_profile_config_file> --output ~/vpn/client.ovpn
curl https://raw.githubusercontent.com/IQEX/todaycrm-community-install/main/install.sh --output ~/install.sh
sudo chmod 755 ~/install.sh
./install.sh
```

Обратите внимание, что client.ovpn файл не входит в состав этого репозитория. Данный файл должен быть у вас свой от вашего VPN. Как его получить - читайте ./docs/VPN.md

Также обратите внимание, что у вашего VPN канала есть внешний публичный адрес, который будет виден как ваш после установки VPN туннеля. Данный IP адрес необходимо прописать в ./install.sh в параметре OPT_VPN_PUBLIC_IP.

Если у вас доступны все нужные пакеты без VPN, то использование VPN можно просто отключить. Для этого в файле install.sh найдите параметр OPT_USE_VPN и поставьте его в значние false.

Если ./install.sh отработал коректно, то в конце вы увидте сообщение

```
DONE
```

3. Выгрузить репозиторий todaycrm-community на свою локальную машину

```
git clone https://github.com/IQEX/todaycrm-community.git
```

4. Отредактируйте файл ./deploy/run_docker_node.bat, заменив в нем параметр HOST_IP на значение публичного адреса созданной виртуальной машины

5. Запустить сборку и развертывание решения

```
cd \deploy
run_docker_node.bat
```

После перехода в bash докер-контейнера необходимо выполнить команду сборки и развертывания решения

```
./deploy.sh
```

В результате в случае полного успеха вы увидте сообщение вида 

```
------------------------------------------------------------------------------------------------
Please open http://${HOST_IP} in your browser to complete installtion procedure
Use login 'deploy' and password 'deploy' for the first login into the system
Good luck!
------------------------------------------------------------------------------------------------
```