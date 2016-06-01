#!/bin/bash
current_directory=`pwd`
source_directory=$current_directory/source

if [ -f SDCard.1.0.8.tar ]
then
#### Comprueba si existe el directorio
#### o lo crea a partir de SDCard.1.0.8.tar
if [ -d image-full-galileo ];
then
echo "          .....directorio image-full-galileo ya existe"
else
tar xvf SDCard.1.0.8.tar
echo "          .....directorio image-full-galileo creado"
fi


echo "          Creando imagen en /galileo-debian....."
#### Comprueba si existe el directorio 
#### si no existe lo crea
if [ -d galileo-debian ];
then
echo "          .....directorio galileo-debian ya existe"
else
mkdir galileo-debian
echo "          .....directorio galileo-debian creado"
fi

cd galileo-debian

if [ -d mnt-loop ];
then
echo "          .....directorio mnt-loop ya existe"
else
mkdir mnt-loop
echo "          .....directorio mnt-loop creado"
fi

if [ -d image ];
then
echo "          .....directorio image ya existe"
else
mkdir image
echo "          .....directorio image creado"
fi

if [ -f loopback.img ];
then
echo "          .....loopback.img ya existe"
else
dd if=/dev/zero of=loopback.img bs=1G count=1
mkfs.ext3 loopback.img
echo "          .....loopback.img creado"
fi

#### Copia el archivo image-full-galileo-clanton en el 
#### directorio galileo-debian
cd ..
cp image-full-galileo/image-full-galileo-clanton.ext3 galileo-debian/
cd galileo-debian/

echo "          Montando mnt-loop, image....."
mount -o loop loopback.img ./mnt-loop

echo "          Montando image....."
mount image-full-galileo-clanton.ext3 image

echo "          Instalando sistema i386 (whezzy)....."
debootstrap --arch i386 wheezy ./mnt-loop http://http.debian.net/debian


#mount -t proc proc mnt-loop/proc
#mount -t sysfs sysfs mnt-loop/sys
#chroot mnt-loop /bin/bash

#############################
#############################
cp -r image/lib/modules mnt-loop/lib
cd mnt-loop
mkdir -p media sketch
mkdir -p opt/cln
cd media
mkdir card cf hdd mmc1 net ram realroot union
cd ../dev
mkdir mtdblock0 mtd0
cd ../..

# copy sys files over
cp -ru image/lib/ mnt-loop/
cp -ru image/usr/lib/libstdc++.so* mnt-loop/usr/lib
cp -ru image/lib/libc.so.0 mnt-loop/usr/lib
cp -ru image/lib/libm.so.0 mnt-loop/usr/lib
cp image/usr/bin/killall mnt-loop/usr/bin/
cp image/etc/inittab mnt-loop/etc/inittab
cp image/etc/modules-load.quark/galileo.conf mnt-loop/etc/modules
cp -r image/opt/ mnt-loop/
cp $source_directory/galileod-gen1.sh mnt-loop/etc/init.d/galileod.sh
chown root:root mnt-loop/etc/init.d/galileod.sh

# uncomment the following line to run getty on gadget serial. note: you must also comment out cp ./galileod line from above to avoid having the galileo scripts using the same serial port
#echo "2:2345:respawn:/sbin/getty 38400 ttyGS0 vt100" >> mnt-loop/etc/inittab

# setup debian image
echo "
auto eth0
iface eth0 inet dhcp
" >> mnt-loop/etc/network/interfaces
echo "Galileo" > mnt-loop/etc/hostname
mount -t proc proc mnt-loop/proc
mount -t sysfs sysfs mnt-loop/sys
cp $source_directory/debian_setup.sh mnt-loop/tmp/debian_setup.sh
chmod +x mnt-loop/tmp/debian_setup.sh
chroot mnt-loop /tmp/debian_setup.sh
rm mnt-loop/tmp/debian_setup.sh

# rollback ssh
cp $source_directory/ssh_rollback.sh mnt-loop/tmp/ssh_rollback.sh
chmod +x mnt-loop/tmp/ssh_rollback.sh
chroot mnt-loop /tmp/ssh_rollback.sh
rm mnt-loop/tmp/ssh_rollback.sh

# rollback git
cp $source_directory/git_rollback.sh mnt-loop/tmp/git_rollback.sh
chmod +x mnt-loop/tmp/git_rollback.sh
chroot mnt-loop /tmp/git_rollback.sh
rm mnt-loop/tmp/git_rollback.sh

# cleanup
umount image
umount mnt-loop/proc
umount mnt-loop/sys
umount mnt-loop
rm image-full-galileo/image-full-galileo-clanton.ext3
cp ./galileo-debian/loopback.img image-full-galileo/image-full-galileo-clanton.ext3
#rm -rf image mnt-loop build

# reminder
echo "          Copia el contenido de la carpeta image-full-galileo en la raiz de tu microSD"
#############################
#############################



else
echo "          .....falta el archivo SDCard.1.0.8.tar.bz2"
fi




