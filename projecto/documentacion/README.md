# Tabla de Contenidos

- [Pre-requisitos](#pre-requisitos)
    - [Multipass](#multipass)
        - [Instalando Multipass](#instalando-multipass)
    - [Instalando Git SCM](#instalando-git-scm)
    - [Instalando FileZilla](#instalando-filezilla)

# Pre-requisitos

<details>
  <summary>Click aqui para ver los pre-requistos</summary>
  
## Multipass

![multipass](assets/img/multipass_logo.png)

[Multipass](https://multipass.run) proporciona una interfaz de línea de comandos para iniciar, administrar y, en general, jugar con instancias 
de Linux. La descarga de una imagen fresca lleva unos segundos, y en cuestión de minutos una VM puede estar en 
funcionamiento.

[Multipass](https://multipass.run) es un software gratuito desarrollado por Ubuntu que permite instalar maquinas virtuales de manera similar
a que si las tuvieramos en un [container](https://www.docker.com).
Las ventajas de Multipass a comparacion de las clasicas maquinas virtuales es basicamente que no se necesita un gran
equipo para poder instancias de ubuntu.
Cuando se habla de una instancia se hace referencia a una imagen que contiene cierto sistema operativo.

### Instalando Multipass

El siguiente link lleva a la descarga de un ejecutable desde el sitio oficial:

- :link: [Link de descarga](https://github.com/canonical/multipass/releases/download/v1.2.1/multipass-1.2.1%2Bwin-win64.exe)

### Habilitando Hyper-V en Windows

Para poder correr cualquier maquina virtual en Windows tenemos que habilitar `Hyper-V`, que por default viene deshabilitado.

Para poder habilitarlo basta con abrir Windows Power Shell (como Administrador), escribir el siguiente comando y reiniciar:

```bash
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

> Si no sabe como abrir Windows Power Shell en Windows vea el siguiente video [como abrir Windows Power Shell en Windows](https://www.youtube.com/watch?v=doUhN9YwZ6U)

## Instalando Git SCM

![Git SCM](assets/img/git_logo.png)

`Git SCM` es una herramienta gratuita de linea de comandos para Windows que nos permitira manejar `multipass` con comandos:

- :link: [Link de descarga](https://git-scm.com/downloads)

## Instalando FileZilla

![FileZilla](assets/img/filezilla_icon.png)

[FileZilla](https://filezilla-project.org) es una herramienta gratuita que nos permite pasar archivos desde una maquina a otra
con mucha facilidad.

- :link: [Link de descaga](https://filezilla-project.org/download.php?platform=win64)

</details>

# Servidores

Con `Multipass` podemos crear dos servidores (con imagenes de Ubuntu), uno nos servira como servidor principal y otro
nos servira como espejo.
La funcion del servidor espejo es tener una copia fiel tanto del sistema operativo, como de los archivos que se encuentran
en el servidor principal, esto quiere decir que si el usuario sube un archivo al servidor principal el servidor espejo
automaticamente tendra el mismo archivo.

## Creando los servidores

A continuacion se detallan los pasos para crear los servidores:

1 - Abrir la consola de `Git CMD` y escribir los siguientes comandos:

```bash
multipass launch --name ftp-servidor-principal
multipass launch --name ftp-servidor-espejo
```

<details>
  <summary>Click aqui para ver un ejemplo de la salida de consola</summary>
  
  ![servers_command_line](assets/img/servers_command_line.png)
  
</details>

> El nombre de los servidores es muy descriptivo por si mismo, notese que al principio del nombre se agrego la palabra
> `ftp` ya que ese es el proposito de estos servidores, servir con el protocolo `ftp` para hacer la funcion de espejo.
