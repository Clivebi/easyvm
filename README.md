# easyvm

use Virtualization.framework to start linuxbased vm (amd64 for intel,arm64 for m1)
support shared folder

# use

1、edit easyVM.json file
```
{   "name":"ubuntu20", //you vm name
    "cdrom": [],       //cdrom image
    //hard disk image,you can use dd command to create a image
    "disk": [
        "/Users/xVM/ubuntu20/disk.img"
    ],
    //shared folder, hostpath,guestpath paired value
    //when start vm,easyvm will output the command to mount devices,
    //you can add that mount command to the .profile file
    "shared": [
        ["/Volumes/work/nvtscript","/opt/nvtscript"],
        ["/Volumes/work/NVTStudio","/opt/NVTStudio"]
    ],
    "cpu": 4,
    "memory": "4GB",
    //linux kernel image
    "kernel": "/Users/xVM/ubuntu20/vmlinuz",
    //linux initrd image
    "initrd": "/Users/xVM/ubuntu20/initrd",
    //linux kernel command line
    "commandline": "console=hvc0 root=/dev/vda"
}
```

2、use easyVM to start VM

use the easyVM.json file in the current directory  

```
./easyVM      
```

use special config file ,example ./debian.json

```
./easyVM  ./debian.json     
```
   
# how to run ubuntu server version use this tool?
 1. download the vmlinuz and initrd image:https://cloud-images.ubuntu.com/releases/focal/release/unpacked/ubuntu-20.04-server-cloudimg-amd64-vmlinuz-generic   to ./ubuntu20/vmlinuz  
 https://cloud-images.ubuntu.com/releases/focal/release/unpacked/ubuntu-20.04-server-cloudimg-arm64-initrd-generic to ./ubuntu20/initrd  
(M1 chip should choose arm64 version)  

 2. download the cloud image : https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.tar.gz and extract to ./ubuntu20/focal-server-cloudimg-amd64.img

 3. dd if=/dev/zero of=./ubuntu20/disk.img bs=1 count=0 seek=30G  to create a hard disk image

 4. now edit config file

 ```
{   "name":"ubuntu20", 
    "cdrom": ["./ubuntu20/focal-server-cloudimg-amd64.img"], 
    "disk": [
        "./ubuntu20/disk.img"
    ],
    "shared": [
        ["/Volumes/work/nvtscript","/opt/nvtscript"],
        ["/Volumes/work/NVTStudio","/opt/NVTStudio"]
    ],
    "cpu": 4,
    "memory": "4GB",
    "kernel": "./ubuntu20/vmlinuz",
    "initrd": "./ubuntu20/initrd",
    "commandline": "console=hvc0"
}
```

use this config file to start VM,you will enter the ubuntu initramfs,now you need copy the cdrom image to disk.img,and modify the root password
```
(initramfs) dd if=/dev/vda of=/dev/vdb bs=1024k &
(initramfs) mkdir /mnt
(initramfs) mount /dev/vdb /mnt
(initramfs) chroot /mnt
root@(none):/# echo 'root:root' | chpasswd
root@(none):/# ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
root@(none):/# ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
root@(none):/# ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
root@(none):/# cat <<EOF > /etc/netplan/01-dhcp.yaml
network:
    renderer: networkd
    ethernets:
        enp0s1:
            dhcp4: no
            addresses: [192.168.64.2/24]
            gateway4: 192.168.64.1
            nameservers:
                addresses: [114.114.114.114]
    version: 2
EOF

root@(none):/# echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
root@(none):/# sed -i "/^PasswordAuthentication/ c PasswordAuthentication yes" /etc/ssh/sshd_config

root@(none):/# exit
```
CTL+C exit
 5. remove cdrom from confile and modify command line 

 ```
{   "name":"ubuntu20", 
    "cdrom": [], 
    "disk": [
        "./ubuntu20/disk.img"
    ],
    "shared": [
        ["/Volumes/work/nvtscript","/opt/nvtscript"],
        ["/Volumes/work/NVTStudio","/opt/NVTStudio"]
    ],
    "cpu": 4,
    "memory": "4GB",
    "kernel": "./ubuntu20/vmlinuz",
    "initrd": "./ubuntu20/initrd",
    "commandline": "console=hvc0 root=/dev/vda"
}
```

now start VM,you will enter the ubuntu 

# reference
1. MacOS Big Sur uses a new virtualization framework to create ultra lightweight virtual machines: https://cdmana.com/2021/01/20210128135648669W.html
