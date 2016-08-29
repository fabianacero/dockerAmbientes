# Ambientes Docker

Se genera dockerFiles para ambientes de desarrollo con las siguientes especificaciones
  1. PHP 5.4 
  2. Apache 2.2
  3. Balanceadores

Mas especificaciones de las imagenes docker en https://hub.docker.com/r/jgomez17/centos-php54/

# Configuraciones
Archivos de configuracion:
  1. configuracion.conf: la cual contendra las rutas de los codigos en su host estan seran expuestas en la ruta del container /var/www/html
  2. En algunas carpetas de los docker existen archivos <b>httpd-vhosts.conf</b> en los cual podran configurar vitualHost a tus necesidades, Ademas se existirá un archivo <b>balancer.conf</b> el cual contendrá la configuración para los balanceadores que se necesite en cada ambiente asi mismo como los hosts requeridos para conecciones entre los container.
  3. Existe un archivo ejecutable para <b>Linux</b> llamado <b>dockerStart.sh</b> en el cual podra hacer los siguientes procesos:<br/>
      a. Instalar las imagenes base de cada ambiente <br/>
      b. Ejecutar/Correr los container de cada ambiente deseado<br/>
      Nota: Si el sistema linux no cuenta con la instalacion de <b>docker</b> el ejecutable se lo instalara automaticamente al igual que en cada proceso verificara que este este corriendo en el sistema.<br/>


<b>Sugerencias</b></br>
Para cambios y/o sugerencias en jerson.gomez0517@gmail.com
