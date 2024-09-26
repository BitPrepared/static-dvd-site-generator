
# Obiettivo
Creare un dvd/usb che possa essere consegnato a chi partecipa ad un evento, con tutti i documenti/applicazioni utilizzate in modo che rimanga un ricordo 

# Build image
Creazione docker image

`make build-image`

## Build local on debian jessie x86 ##

Prima dell'installazione (npm install) controllare le dipendenze

~~~
curl -sL https://deb.nodesource.com/setup_8.x | bash
apt install libmagick++-dev
~~~

e alla fine eseguire 

~~~
export PATH=/usr/lib/i386-linux-gnu/ImageMagick-6.8.9/bin-Q16:$PATH
~~~

# Build usb/dvd image

`make build-dvd`


## Alberatura Intranet ##
NOTA: (vedi .htaccess -> ~/www/intranet)

 * http://local.bitprepared.it/sito/ -> ~/www/intranet/sito
 * http://local.bitprepared.it/ -> ~/www/intranet/sito
 * http://local.bitprepared.it/ -> ~/www/intranet/dashboard
 * http://local.bitprepared.it/argh/web/login -> ~/www/intranet/argh/web/


## TODO
- [ ] serve da implementare l'ultimo comando in make per la sync su chiavetta usb
- [ ] serve comando per creare iso 
- [ ] serve il reset della struttura dati 
- [ ] 