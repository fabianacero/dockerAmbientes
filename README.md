# Ambientes Docker

Se genera dockerFiles para ambientes de desarrollo con las siguientes especificaciones
  1. PHP 5.4 
  2. Apache 2.2
  3. Balanceadores

Mas especificaciones de las imagenes docker en https://hub.docker.com/r/jgomez17/centos-php54/

# Configuraciones
Archivos de configuracion:
  1. configuracion.conf: la cual contendra las rutas de los codigos en su host estan seran expuestas en la ruta del container /var/www/html
  2. En algunas carpetas de los docker existe archivos <b>httpd-vhosts.conf</b> en el cual podran configurar vitualHost a tus necesidades, Ademas se existirá un archivo <b>balancerXXX.conf</b> el cual contendrá la configuración para los balanceadores que se necesite en cada ambiente.

<b>Sugerencias</b></br>
Para cambios y/o sugerencias en jerson.gomez0517@gmail.com
