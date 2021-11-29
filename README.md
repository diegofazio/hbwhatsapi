# hbWhatsapi
Whatsapp <-> Harbour API via puppeteer/whatsapp-web.js


### How to install

Mysql db
1) Create Mysql DBs. Import db.zip

Node server 

1) Install node(not full installation required) https://nodejs.org/es/download/
2) Create folder and clone the repo *1
3) Run inside folder created -> npm init -y 
4) Run inside folder created -> npm install whatsapp-web.js qrcode mysql
5) Set user/pass/host/port of Mysql DB( whatsapp_in and whatsapp_out ) in index.js
6) Start server -> node index.js

Client for HW_Apache(http://www.hbtron.com/downloads.html)

1) Copy client.* to htdocs
2) Set user/pass/host/port of Mysql DB( whatsapp_in and whatsapp_out ) in client.prg
3) Set the *1 folder created in SESSION_PATH in client.prg
3) Go to http://localhost/client.html

NOTE: If you use modharbour replace HW_WRITE -> AP_RWRITE in client.prg

# http://www.hbtron.com
<img src="http://www.hbtron.com/hwtools512.png" width="250" title="hw_tools">
