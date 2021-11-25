# hbWhatsapi
Whatsapp <-> Harbour API

### How to install

Mysql db
1) Create Mysql DBs. Import db.zip

Node server 

1) Install node(not full installation required) https://nodejs.org/es/download/
2) Create folder and clone the repo
3) Run inside folder created -> npm init -y 
4) Run inside folder created -> npm install whatsapp-web.js qrcode
5) Set user/pass/host/port of Mysql DB( whatsapp_in and whatsapp_out ) in index.js
6) Start server -> node index.js

Client for HW_Apache

1) Copy client.* to htdocs
2) Set user/pass/host/port of Mysql DB( whatsapp_in and whatsapp_out ) in client.prg
3) Go to http://localhost/client.html
