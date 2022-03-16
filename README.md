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
2、use easyVM to start VM，（use the easyVM.json file in the current directory)
   use easyVM config file path to start VM with special confile
   
# how to run ubuntu server version use this tool?
 1. download the vmlinuz and initrd image:https://cloud-images.ubuntu.com/releases/focal/release/unpacked/ubuntu-20.04-server-cloudimg-amd64-vmlinuz-generic https://cloud-images.ubuntu.com/releases/focal/release/unpacked/ubuntu-20.04-server-cloudimg-arm64-initrd-generic (M1 chip should chooise arm64 version)
 2. download the cloud image and extrat it. https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.tar.gz
 3. dd if=/dev/zero of=disk.img bs=1 count=0 seek=30G  to create a hard disk image
 4. edit the config,add cmrom to the cloud image path,disk to the disk iamge,set the vmlinxz initrd path,the command line set 
 5. start vm and copy cdrom to the disk
 more detail can found here:https://cdmana.com/2021/01/20210128135648669W.html
