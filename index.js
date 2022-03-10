
var mysql = require('mysql');

var con = mysql.createConnection({
   host: 'localhost',
   user: 'harbour',
   password: '',
   database: 'harbourdb'
});

con.connect((err) => {
   if (err) {
      console.log('Error connecting to Db');
      process.exit();
   }
   console.log('Connection established');
});

const fs = require('fs');

const cPath = "./";
//const qrcode = require('qrcode-terminal')
const qrcode_file = require('qrcode')
const QR_CODE = cPath + 'qrcode.png';
const SESSION_FILE_PATH = cPath + 'session.json';

const { Client, LocalAuth } = require('whatsapp-web.js');
const { MessageMedia } = require('whatsapp-web.js');


var connected = false;

const client1 = new Client({
   authStrategy: new LocalAuth()
});

client1.on('qr', qr => {

   qrcode_file.toFile(QR_CODE, qr);

});

client1.on('ready', () => {
   console.log('Conectado');
   fs.writeFile(SESSION_FILE_PATH, 'INIT SESSION', function (err) {
      if (err) throw err;
      console.log('File is created successfully.');
    });     
   deleteQR();
   connected = true;

});

client1.on('auth_failure', msg => {
   console.log('Error de autenticación', msg);
});

client1.on('message', async msg => {

   if (msg.hasMedia) {
      const media = await msg.downloadMedia();
      const wsap_msg = { from: msg.from, mimetype: media.mimetype, data: media.data, filename: media.filename, status: 0, timestamp: msg.timestamp };
      con.query('INSERT INTO whatsapp_in SET ?', wsap_msg, (err, res) => {
         if (err) throw err;
         console.log('Last insert ID:', res.insertId);
      });

   } else {
      if (msg.body != '') {
         const buff = Buffer.from(msg.body, 'utf-8');
         const base64 = buff.toString('base64');
         const wsap_msg = { from: msg.from, mimetype: 'text', data: base64, status: 0, timestamp: msg.timestamp };
         con.query('INSERT INTO whatsapp_in SET ?', wsap_msg, (err, res) => {
            if (err) throw err;
         });
      };
   };

})


client1.on('disconnected', (reason) => {
   deleteSESSION();
   console.log("disconnected");
   client1.initialize();
   connected = false;
});

client1.initialize().then(session => {
   console.log('Session restored', session);
   connected = true;
}).catch(err => {
   console.log('Initialization error, es necesario actualizar?', err);
   deleteSESSION();
   deleteQR()
   process.exit();
});

function checkNewMessage() {
   if (connected) {
      connected = false;
      var ID = 0;
      con.query('SELECT * FROM whatsapp_out WHERE STATUS = 0 LIMIT 1', (err, rows) => {
         if (err) throw err;
         if (rows.length > 0) {
            var b64string = rows[0]['data'];
            ID = rows[0]['ID'];
            if (rows[0]['mimetype'] == 'text') {
               msg = Buffer.from(b64string, 'base64').toString('utf8');
               client1.sendMessage(rows[0]['to'] + "@c.us", msg)
                  .then(response => {
                     if (response.id.fromMe) {
                        console.log('Mensaje enviado:', rows[0]['mimetype']);

                     }
                  });
            } else {
               const media = new MessageMedia(rows[0]['mimetype'], b64string.toString(), rows[0]['filename']);
               client1.sendMessage(rows[0]['to'] + "@c.us", media, { caption: rows[0]['caption'] })
                  .then(response => {
                     if (response.id.fromMe) {
                        console.log('Mensaje enviado:', rows[0]['mimetype']);
                     }
                  });
               console.log(rows[0]['mimetype'])
            }
            con.query('UPDATE whatsapp_out SET STATUS = 1 WHERE ID = ?', ID, (err, res) => {
               if (err) throw err;
            });
         };
      });
      connected = true;
   };
};

function deleteQR() {
   fs.stat(QR_CODE, function (err, stats) {

      if (err) {
         //         return console.error(err);
      }

      fs.unlink(QR_CODE, function (err) {
         //         if (err) return console.log(err);
      });
   });

}

function deleteSESSION() {
   fs.stat(SESSION_FILE_PATH, function (err, stats) {

      if (err) {
         //         return console.error(err);
      }

      fs.unlink(SESSION_FILE_PATH, function (err) {
         if (err) return console.log(err);
      });
   });

}

process.on('exit', function () {
   console.log('exit');
   fs.unlink(SESSION_FILE_PATH, function (err) {
      //      if (err) return console.log(err);
   });
   fs.unlink(QR_CODE, function (err) {
      //         if (err) return console.log(err);
   });
});


intervalid = setInterval(checkNewMessage, 1000);
