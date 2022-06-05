# node-nginx-vodtest-server

excecution step : teraform apply

Creates 2 docker containers

- (1) node application (2) nginx proxy server

- excecute.sh script is executed by user_data in EC2 instance during the launch

- execute.sh (1) Installs all needed modules (2) copies data from app_dir to S3 bucket .

- SSL support is provided in nginx.conf , further need to add cert and private key .

- verify after EC2 instance launch state is set to running :

ubuntu@ip-10-0-1-56:~$ sudo docker ps

CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
31f1561d9aa6 application_nginx "nginx -g 'daemon of…" About a minute ago Up About a minute 0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp application_nginx_1
d632ffab6140 application_web "node server.js" About a minute ago Up About a minute 3000/tcp application_web_1
