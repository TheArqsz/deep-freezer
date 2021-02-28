translate() {
    sed -i "s/Eliminando archivos de configuracion/Deleting configuration files/g" $1
    sed -i "s/Eliminando archivos de initramfs/Removing files from initramfs/g" $1
    sed -i "s/Eliminando configuraciones de grub/Removing grub settings/g" $1
    sed -i "s/Regenerando la imagen initramfs... Esto puede tomar unos minutos./Rebuilding the initramfs image ... This may take a few minutes./g" $1
}

update_postrm() {
    [ -z /var/lib/dpkg/info/lethe.postrm ] && return
    translate /var/lib/dpkg/info/lethe.postrm 
    sed -i "s/rm -rv \/etc\/lethe >&2/\[ -e \/etc\/lethe \] \&\& rm -rv \/etc\/lethe 2>\/var\/log\/lethe.error.log/g" /var/lib/dpkg/info/lethe.postrm 
    sed -i "s/rm -v \/etc\/initramfs-tools\/scripts\/__lethe/\[ -e \/etc\/initramfs-tools\/scripts\/__lethe \] \&\& rm -v \/etc\/initramfs-tools\/scripts\/__lethe 2>\/var\/log\/lethe.error.log/g" /var/lib/dpkg/info/lethe.postrm 
    sed -i "s/rm -v \/etc\/initramfs-tools\/scripts\/local-bottom\/lethe/\[ -e \/etc\/initramfs-tools\/scripts\/local-bottom\/lethe \] \&\& rm -v \/etc\/initramfs-tools\/scripts\/local-bottom\/lethe 2>\/var\/log\/lethe.error.log/g" /var/lib/dpkg/info/lethe.postrm 
    dpkg --configure -a
}

update_boot() {
    cp ./files/09_lethe /etc/grub.d/09_lethe
}