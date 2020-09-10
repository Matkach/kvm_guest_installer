#!/bin/bash

if [ "$EUID" -ne 0 ] ; then echo "Please run as root" ; exit ; fi

function questions {
  ##### Interactive questions
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "Please insert the information required for the KVM guest installation."
  echo "Please note that the values are for all the selected choices"
  echo "You can run the script multiple times with deferent values to reach your goal"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo -e "\e[32mKVM guest hostname:\e[39m "
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  read hostname

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo -e "\e[32mKVM guest disk size (in GB):\e[39m "
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  read size

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo -e "\e[32mKVM guest RAM Memory to allocate (in MB):\e[39m "
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  read ram

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo -e "\e[32mEnter a number of virtual cpus:\e[39m "
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  read vcpu

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo -e "\e[32mEnter a root password for KVM $hostname:\e[39m "
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  read root_password
}

function main_install {

  OS_ID=$(cat /etc/*release | grep VERSION_ID | cut -d\" -f2)
  echo "====================================================="
  echo -e "\e[32mOS FOUND: ${OS_ID}\e[39m"
  echo "====================================================="
  echo ""
  echo -e "\e[32mVirtualization host installation\e[39m"
  echo ""
  echo "This script will install all the necessary packages to use Libvirtd/KVM"

  if [ "$OS_ID" == "18.04" ]; then
    apt update ; apt upgrade -y ; apt install -y qemu qemu-kvm libvirt-bin bridge-utils virt-manager virt-viewer libvirt-clients libvirt-daemon-system bridge-utils virt-top libguestfs-tools ; systemctl enable libvirtd ; systemctl start libvirtd
   elif [ "$OS_ID" == "20.04" ]; then
    apt update ; apt upgrade -y ; apt install -y qemu qemu-kvm bridge-utils virt-manager virt-viewer libvirt-clients libvirt-daemon-system bridge-utils virt-top libguestfs-tools ; systemctl enable libvirtd ; systemctl start libvirtd
  elif [ "$OS_ID" == "8" ]; then
    dnf update -y ; dnf install -y qemu-kvm qemu-img libvirt virt-install libvirt-client virt-top libguestfs-tools ; systemctl enable libvirtd ; systemctl start libvirtd
  elif [ "$OS_ID" == "7" ]; then
    yum update -y ; yum -y install qemu-kvm libvirt libvirt-python libguestfs-tools virt-install libguestfs-xfs virt-top ; systemctl enable libvirtd ; systemctl start libvirtd
  else
    echo "Unknown OS. Exiting..."
    exit 1
  fi

}

function e2fsck {

e2fsck -V
yum groupinstall "Development Tools" -y
wget https://mirrors.edge.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.45.4/e2fsprogs-1.45.4.tar.gz
tar -xzf e2fsprogs-1.45.4.tar.gz
cd e2fsprogs-1.45.4
mkdir build; cd build
../configure
make
make install
}

mkdir -p /vmdata

# osinfo-query os

function ubuntu16 {

#enter variables by answering the questions
questions

#build Ubuntu 16.04 KVM guest:

virt-builder ubuntu-16.04 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--firstboot-command "dpkg-reconfigure openssh-server" \
--edit '/etc/default/grub:
s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"/' \
--edit '/etc/network/interfaces:
s/^ens2.*/ens3/' \
--run-command update-grub \
--run-command 'apt -y update' \
--root-password password:$root_password --no-check-signature

#install Ubuntu 16.04 KVM guest:

virt-install --import --name $hostname \
--virt-type=qemu \
--ram $ram \
--vcpu $vcpu \
--disk path=/vmdata/$hostname.img,format=raw \
--os-variant ubuntu16.04 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot

#sed -i 's/ens2/ens3/g' /etc/network/interfaces
#virt-edit -d $hostname /etc/network/interfaces -e 's/ens2/ens3/g'
#virt-edit -d kvm7 /etc/systemd/system/getty.target.wants/getty@tty1.service -e 's/"ExecStart=-/sbin/agetty --noclear %I $TERM"/"ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM"/g'

}

#***************************

function ubuntu18 {

#enter variables by answering the questions
questions

#build Ubuntu18.04 KVM guest:

virt-builder ubuntu-18.04 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--firstboot-command "dpkg-reconfigure openssh-server" \
--edit '/etc/default/grub:
s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"/' \
--run-command update-grub \
--run-command 'apt -y update' \
--root-password password:$root_password --no-check-signature

#install Ubuntu18.04 KVM guest:

virt-install --import --name $hostname \
--virt-type=qemu \
--ram $ram \
--vcpu $vcpu \
--disk path=/vmdata/$hostname.img,format=raw \
--os-variant ubuntu18.04 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot

#sed -i 's/ens2/enp1s0/g' /etc/netplan/01-netcfg.yaml
}

#***************************

function centos7 {

#enter variables by answering the questions
questions

#build CentOS 7 KVM guest:

virt-builder centos-7.7 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--root-password password:$root_password --no-check-signature

#install CentOS 7 KVM guest:

virt-install --import \
--name $hostname \
--virt-type=qemu \
--ram $ram \
--disk path=/vmdata/$hostname.img \
--vcpus $vcpu \
--os-variant centos7.0 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot

}

#***************************

function centos8 {

#enter variables by answering the questions
questions

#install CentOS 8 KVM guest:

virt-builder centos-8.2 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--root-password password:$root_password --no-check-signature

#install CentOS 8 KVM guest:

virt-install --import \
--name $hostname \
--virt-type=qemu \
--ram $ram \
--disk path=/vmdata/$hostname.img \
--vcpus $vcpu \
--os-variant centos8 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot
}

#***************************

function debian9 {

#enter variables by answering the questions
questions

#build Debian 9 KVM guest:

virt-builder debian-9 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--firstboot-command "dpkg-reconfigure openssh-server" \
--edit '/etc/default/grub:
s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"/' \
--run-command update-grub \
--run-command 'apt -y update' \
--root-password password:$root_password --no-check-signature

#install Debian 9 KVM guest:

virt-install --import --name $hostname \
--virt-type=qemu \
--ram $ram \
--vcpu $vcpu \
--disk path=/vmdata/$hostname.img,format=raw \
--os-variant debian9 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot

}

#sed -i 's/ens2/enp1s0/g' /etc/network/interfaces

#***************************

function debian10 {

#enter variables by answering the questions
questions

#build Debian 10 KVM guest:

virt-builder debian-10 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--firstboot-command "dpkg-reconfigure openssh-server" \
--edit '/etc/default/grub:
s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"/' \
--run-command update-grub \
--run-command 'apt -y update' \
--root-password password:$root_password --no-check-signature

#install Debian 10 KVM guest:

virt-install --import --name $hostname \
--virt-type=qemu \
--ram $ram \
--vcpu $vcpu \
--disk path=/vmdata/$hostname.img,format=raw \
--os-variant debian10 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot

}

#sed -i 's/ens2/enp1s0/g' /etc/network/interfaces

#***************************

function fedora31 {

#enter variables by answering the questions
questions

#install Fedora 31 KVM guest:

virt-builder fedora-31 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--root-password password:$root_password --no-check-signature

#install Fedora 31 KVM guest:

virt-install --import \
--name $hostname \
--virt-type=qemu \
--ram $ram \
--disk path=/vmdata/$hostname.img \
--vcpus $vcpu \
--os-type linux \
--os-variant fedora31 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot
}

#***************************

function fedora32 {

#enter variables by answering the questions
questions

#install Fedora 32 KVM guest:

virt-builder fedora-32 \
--size=$size\G --format raw -o /vmdata/$hostname.img \
--hostname $hostname --network \
--root-password password:$root_password --no-check-signature

#install Fedora 32 KVM guest:

virt-install --import \
--name $hostname \
--virt-type=qemu \
--ram $ram \
--disk path=/vmdata/$hostname.img \
--vcpus $vcpu \
--os-variant fedora31 \
--network=bridge=virbr0,model=virtio \
--noautoconsole \
--noreboot
}

#***************************

function main {

    declare -A selection;
    declare -a items;

    selection[ubuntu16]="  Ubuntu 16.04  "; items+=( ubuntu16 )
    selection[ubuntu20]="  Ubuntu 20.04  "; items+=( ubuntu20 )
    selection[centos7]="  CentOS 7  "; items+=( centos7 )
    selection[centos8]="  CentOS 8  "; items+=( centos8 )
    selection[debian9]="  Debian 9  "; items+=( debian9 )
    selection[debian10]="  Debian 10  "; items+=( debian10 )
    selection[fedora31]="  Fedora 31  "; items+=( fedora31 )
    selection[fedora32]="  Fedora 32  "; items+=( fedora32 )

    entry_options=()
    entries_count=${#selection[@]}
    message=$'Choose what to be installed. The below choices can be selected.\n\nInstallation list:\n\n'
    choices=()

    for i in "${items[@]}"
    do
        entry_options+=("$i")
        entry_options+=("${selection[$i]}")
        entry_options+=("ON")
    done

    selected_installations=$(whiptail --checklist --separate-output --title "Choose services" "$message" 20 60 $entries_count -- "${entry_options[@]}" 3>&1 1>&2 2>&3)
    mapfile -t choices <<< "$selected_installations"

    # Install qemu-kvm
    main_install

    for selected in "${choices[@]}"; do
        # run all selected functions
        $selected
    done
}

# Call main function
main

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo -e "\e[32mInstallation complete.\e[39m"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
